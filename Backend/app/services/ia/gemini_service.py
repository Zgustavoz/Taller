import json
import re
import base64
import httpx
from google import genai
from app.core.config import settings

# ─── Cliente SDK v2 ───────────────────────────────────────────
_client = genai.Client(api_key=settings.GEMINI_API_KEY)
_MODELO = "gemini-flash-latest"

# ─── Mapa tipo → especialidades de taller ────────────────────
TIPO_A_ESPECIALIDAD: dict[str, list[str]] = {
    "flat_tire":       ["llanta"],
    "battery_dead":    ["bateria", "electrico"],
    "engine_overheat": ["motor"],
    "minor_accident":  ["choque", "carroceria"],
    "electrical":      ["electrico", "bateria"],
    "lost_keys":       ["cerrajeria", "general"],
    "fuel_empty":      ["general"],
    "other":           [],
}


def especialidades_para_tipo(tipo: str) -> list[str]:
    return TIPO_A_ESPECIALIDAD.get(tipo, [])


def _limpiar_json(texto: str) -> str:
    """Extrae JSON limpio de la respuesta de Gemini."""
    texto = texto.strip()
    texto = re.sub(r"```(?:json)?\s*", "", texto)
    texto = re.sub(r"```", "", texto)
    texto = texto.strip()
    inicio = texto.find("{")
    fin = texto.rfind("}") + 1
    if inicio != -1 and fin > inicio:
        return texto[inicio:fin]
    return texto


# ─── Analizar incidente completo ──────────────────────────────
async def analizar_incidente(
    descripcion: str | None,
    urls_imagenes: list[str],
    urls_audios: list[str],
    transcripciones_audio: list[str] | None = None,
    tipo_nombre: str | None = None,
) -> dict:
    """Analiza el incidente con Gemini. Devuelve JSON estructurado."""

    texto_transcripciones = "\n".join(transcripciones_audio or [])
    print(f"[Gemini] urls_audios recibidas: {urls_audios}")
    print(f"[Gemini] transcripciones_audio: {texto_transcripciones!r}")

    prompt = f"""Eres un sistema experto en diagnóstico de emergencias vehiculares.
Analiza la información del incidente y clasifícalo con precisión.

INFORMACIÓN DEL INCIDENTE:
- Descripción del usuario: "{descripcion or 'No proporcionada'}"
- Transcripción de audio: "{texto_transcripciones or 'No hay audio'}"
- Imágenes adjuntas: {len(urls_imagenes)}
- Audios adjuntos: {len(urls_audios)}

TIPOS DISPONIBLES:
- flat_tire: pinchazo, llanta baja, desinflada
- battery_dead: batería descargada, no enciende, no arranca
- engine_overheat: motor caliente, humo, temperatura alta
- minor_accident: choque, golpe, colisión leve, abolladura
- lost_keys: perdió llaves, llave dentro del auto
- fuel_empty: sin gasolina, sin combustible
- electrical: falla eléctrica, luces, fusibles, alternador
- other: problema no identificado

Responde ÚNICAMENTE con este JSON válido, sin texto ni markdown adicional:
{{
  "tipo_detectado": "flat_tire",
  "confianza": 0.85,
  "nivel_prioridad": 3,
  "transcripcion_audio": "texto transcrito del audio si existe, o null si no hay audio",
  "resumen": "Breve descripción del problema en 1-2 oraciones.",
  "ficha_resumen": {{
    "problema_principal": "Descripción específica del problema",
    "recomendacion": "Qué debe hacer el usuario mientras espera",
    "urgencia": "baja|media|alta|critica",
    "herramientas_necesarias": ["herramienta1", "herramienta2"],
    "especialidad_requerida": "tipo de especialidad del taller"
  }},
  "danos_detectados": [],
  "palabras_clave": []
}}

REGLAS:
- nivel_prioridad: 1=baja, 2=media-baja, 3=media, 4=alta, 5=crítica
- confianza: 0.0 a 1.0
- urgencia: baja/media/alta/critica
- Sin info suficiente → tipo "other", confianza 0.3"""

    # Construir partes del contenido
    partes: list = [prompt]

    # Adjuntar imágenes (máx 3)
    async with httpx.AsyncClient(timeout=30) as http:
        for url in urls_imagenes[:3]:
            try:
                res = await http.get(url)
                if res.status_code == 200:
                    partes.append({
                        "inline_data": {
                            "mime_type": res.headers.get("content-type", "image/jpeg"),
                            "data": base64.b64encode(res.content).decode(),
                        }
                    })
            except Exception:
                continue

    try:
        response = _client.models.generate_content(
            model=_MODELO,
            contents=partes,
        )
        texto = response.text.strip()
        resultado = json.loads(_limpiar_json(texto))

        # Validar campos mínimos
        for campo in ["tipo_detectado", "confianza", "nivel_prioridad",
                       "resumen", "ficha_resumen"]:
            if campo not in resultado:
                raise ValueError(f"Campo faltante en respuesta IA: {campo}")

        # Normalizar ficha_resumen
        ficha = resultado["ficha_resumen"]
        resultado["ficha_resumen"] = {
            "problema_principal": ficha.get("problema_principal", descripcion or "No especificado"),
            "recomendacion": ficha.get("recomendacion", "Espere en un lugar seguro"),
            "urgencia": ficha.get("urgencia", "media"),
            "herramientas_necesarias": ficha.get("herramientas_necesarias") or [],
            "especialidad_requerida": ficha.get("especialidad_requerida", "mecánica general"),
        }

        # Normalizar listas opcionales
        resultado["danos_detectados"] = resultado.get("danos_detectados") or []
        resultado["palabras_clave"] = resultado.get("palabras_clave") or []

        # Normalizar transcripción de audio
        transcripcion_audio = resultado.get("transcripcion_audio")
        if isinstance(transcripcion_audio, str):
            transcripcion_audio = transcripcion_audio.strip()
            if transcripcion_audio.lower() in [
                "no hay audio",
                "null",
                "nulo",
                "texto transcrito del audio si existe, o null si no hay audio",
            ]:
                transcripcion_audio = None
        if not transcripcion_audio and texto_transcripciones:
            transcripcion_audio = texto_transcripciones
        resultado["transcripcion_audio"] = transcripcion_audio

        print(f"[Gemini] ✅ {resultado['tipo_detectado']} "
              f"(confianza {resultado['confianza']:.0%}, "
              f"prioridad {resultado['nivel_prioridad']})")
        return resultado

    except Exception as e:
        print(f"[Gemini] ❌ Error: {e}")
        return _fallback(descripcion, texto_transcripciones)


# ─── Transcribir audio ────────────────────────────────────────
async def transcribir_audio(url_audio: str, mime_type: str | None = None) -> str | None:
    """Transcribe audio desde Cloudinary con Gemini."""
    try:
        async with httpx.AsyncClient(timeout=30) as http:
            res = await http.get(url_audio)
            if res.status_code != 200:
                return None

        final_mime = mime_type or res.headers.get("content-type", "audio/wav")
        print(f"[Gemini] 🎤 Transcribiendo con MIME type: {final_mime}")
        response = _client.models.generate_content(
            model=_MODELO,
            contents=[
                "Transcribe EXACTAMENTE lo que dice este audio en español. "
                "Devuelve SOLO la transcripción, sin comentarios adicionales.",
                {
                    "inline_data": {
                        "mime_type": final_mime,
                        "data": base64.b64encode(res.content).decode(),
                    }
                },
            ],
        )
        transcripcion = response.text.strip()
        print(f"[Gemini] 🎤 Audio transcrito: {transcripcion[:80]}...")
        return transcripcion

    except Exception as e:
        print(f"[Gemini] ❌ Error transcribiendo audio: {e}")
        return None


# ─── Analizar imagen ──────────────────────────────────────────
async def analizar_imagen(url_imagen: str) -> dict:
    """Analiza imagen de vehículo con Gemini Vision."""
    try:
        async with httpx.AsyncClient(timeout=30) as http:
            res = await http.get(url_imagen)
            if res.status_code != 200:
                return {}

        response = _client.models.generate_content(
            model=_MODELO,
            contents=[
                "Analiza esta imagen de un vehículo con problemas. "
                "Responde ÚNICAMENTE con este JSON válido sin markdown:\n"
                "{\n"
                '  "danos_detectados": ["descripción del daño visible"],\n'
                '  "tipo_probable": "flat_tire|battery_dead|engine_overheat|minor_accident|other",\n'
                '  "confianza": 0.85,\n'
                '  "partes_afectadas": ["parte afectada"],\n'
                '  "severidad": "leve|moderado|grave"\n'
                "}",
                {
                    "inline_data": {
                        "mime_type": res.headers.get("content-type", "image/jpeg"),
                        "data": base64.b64encode(res.content).decode(),
                    }
                },
            ],
        )
        texto = response.text.strip()
        resultado = json.loads(_limpiar_json(texto))
        print(f"[Gemini] 🖼️ Imagen analizada: {resultado.get('tipo_probable')} "
              f"({resultado.get('severidad')})")
        return resultado

    except Exception as e:
        print(f"[Gemini] ❌ Error analizando imagen: {e}")
        return {}


# ─── Fallback con palabras clave ──────────────────────────────
def _fallback(
    descripcion: str | None,
    transcripcion: str | None = None,
) -> dict:
    """Clasificación por palabras clave cuando Gemini falla."""
    texto = f"{descripcion or ''} {transcripcion or ''}".lower()

    tipo = "other"
    herramientas: list[str] = []
    especialidad = "mecánica general"

    if any(p in texto for p in ["llanta", "pinchazo", "rueda", "desinflad", "pincho"]):
        tipo, herramientas, especialidad = (
            "flat_tire",
            ["gato hidráulico", "llave de ruedas", "llanta de repuesto"],
            "servicio de llantas",
        )
    elif any(p in texto for p in ["batería", "bateria", "no enciende", "no arranca", "corriente"]):
        tipo, herramientas, especialidad = (
            "battery_dead",
            ["cargador de batería", "cables de arranque"],
            "electricidad automotriz",
        )
    elif any(p in texto for p in ["caliente", "humo", "temperatura", "sobrecalent", "recalent"]):
        tipo, herramientas, especialidad = (
            "engine_overheat",
            ["agua destilada", "refrigerante"],
            "mecánica de motor",
        )
    elif any(p in texto for p in ["choque", "golpe", "accidente", "colisión", "abollad", "raspon"]):
        tipo, herramientas, especialidad = (
            "minor_accident",
            ["grúa", "herramientas de carrocería"],
            "carrocería y mecánica",
        )
    elif any(p in texto for p in ["gasolina", "combustible", "diesel", "tanque", "sin gas"]):
        tipo, herramientas, especialidad = (
            "fuel_empty",
            ["bidón de combustible"],
            "asistencia en ruta",
        )
    elif any(p in texto for p in ["llave", "perdí", "cerrado", "encerrado", "no abre"]):
        tipo, herramientas, especialidad = (
            "lost_keys",
            ["kit de apertura"],
            "cerrajería automotriz",
        )
    elif any(p in texto for p in ["luz", "fusible", "eléctric", "alternador", "cortocircuito"]):
        tipo, herramientas, especialidad = (
            "electrical",
            ["multímetro", "fusibles de repuesto"],
            "electricidad automotriz",
        )

    return {
        "tipo_detectado": tipo,
        "confianza": 0.6 if tipo != "other" else 0.3,
        "nivel_prioridad": 3,
        "transcripcion_audio": transcripcion,
        "resumen": descripcion or transcripcion or "Emergencia vehicular sin descripción",
        "ficha_resumen": {
            "problema_principal": descripcion or transcripcion or "No especificado",
            "recomendacion": "Manténgase en un lugar seguro y espere al técnico asignado.",
            "urgencia": "media",
            "herramientas_necesarias": herramientas,
            "especialidad_requerida": especialidad,
        },
        "danos_detectados": [],
        "palabras_clave": texto.split()[:5],
    }