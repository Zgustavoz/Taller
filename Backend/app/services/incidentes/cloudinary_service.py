import cloudinary
import cloudinary.uploader
from fastapi import UploadFile, HTTPException, status
from app.core.config import settings

# Configurar Cloudinary
cloudinary.config(
    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True,
)

# Tipos permitidos por categoría
TIPOS_IMAGEN = {"image/jpeg", "image/png", "image/webp", "image/gif"}
TIPOS_AUDIO = {"audio/mpeg", "audio/wav", "audio/ogg", "audio/mp4", "audio/webm"}
TIPOS_VIDEO = {"video/mp4", "video/webm", "video/ogg", "video/quicktime"}

MAX_SIZE_BYTES = 50 * 1024 * 1024  # 50 MB


def detectar_tipo_archivo(content_type: str) -> str:
    if content_type in TIPOS_IMAGEN:
        return "imagen"
    if content_type in TIPOS_AUDIO:
        return "audio"
    if content_type in TIPOS_VIDEO:
        return "video"
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=f"Tipo de archivo no soportado: {content_type}",
    )


def detectar_resource_type(content_type: str) -> str:
    if content_type in TIPOS_IMAGEN:
        return "image"
    if content_type in TIPOS_AUDIO:
        return "raw"
    if content_type in TIPOS_VIDEO:
        return "video"
    return "auto"


async def subir_archivo_cloudinary(
    archivo: UploadFile,
    carpeta: str = "incidentes",
) -> dict:
    # Validar tipo
    content_type = archivo.content_type or ""
    tipo_archivo = detectar_tipo_archivo(content_type)
    resource_type = detectar_resource_type(content_type)

    # Leer contenido
    contenido = await archivo.read()

    # Validar tamaño
    if len(contenido) > MAX_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El archivo excede el límite de 50MB",
        )

    try:
        resultado = cloudinary.uploader.upload(
            contenido,
            folder=carpeta,
            resource_type=resource_type,
        )
        return {
            "url": resultado.get("secure_url"),
            "public_id": resultado.get("public_id"),
            "tipo_archivo": tipo_archivo,
            "tipo_mime": content_type,
            "tamano_bytes": len(contenido),
            "duracion_seg": resultado.get("duration"),  # solo para audio/video
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al subir archivo a Cloudinary: {str(e)}",
        )


async def eliminar_archivo_cloudinary(public_id: str, resource_type: str = "image") -> bool:
    try:
        cloudinary.uploader.destroy(public_id, resource_type=resource_type)
        return True
    except Exception:
        return False