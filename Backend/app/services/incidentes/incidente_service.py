from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from app.repositories.incidentes.incidente_repository import IncidenteRepository
from app.schemas.incidente_schema import IncidenteCreate, IncidenteUpdate
from app.models.historial_estado_model import HistorialEstado
from app.services.incidentes.estado_validator import EstadoIncidenteValidator


class IncidenteService:

    def __init__(self, db: AsyncSession):
        self.repo = IncidenteRepository(db)

    def _serializar(self, incidente, coordenadas: Optional[dict] = None) -> dict:
        data = {
            "id": incidente.id,
            "usuario_id": incidente.usuario_id,
            "vehiculo_id": incidente.vehiculo_id,
            "taller_asignado_id": incidente.taller_asignado_id,
            "tecnico_asignado_id": incidente.tecnico_asignado_id,
            "tipo_incidente_id": incidente.tipo_incidente_id,
            "latitud": coordenadas["latitud"] if coordenadas else None,
            "longitud": coordenadas["longitud"] if coordenadas else None,
            "texto_direccion": incidente.texto_direccion,
            "descripcion": incidente.descripcion,
            "estado": incidente.estado,
            "nivel_prioridad": incidente.nivel_prioridad,
            "analisis_ia": incidente.analisis_ia,
            "ficha_resumen": incidente.ficha_resumen,
            "tiempo_estimado_llegada_min": incidente.tiempo_estimado_llegada_min,
            "vehiculo": {
                "id": incidente.vehiculo.id,
                "marca": incidente.vehiculo.marca,
                "modelo": incidente.vehiculo.modelo,
                "placa": incidente.vehiculo.placa,
                "url_foto": incidente.vehiculo.url_foto,
            } if incidente.vehiculo else None,
            "taller": {
                "id": incidente.taller.id,
                "nombre_negocio": incidente.taller.nombre_negocio,
                "telefono": incidente.taller.telefono,
                "correo": incidente.taller.correo,
            } if incidente.taller else None,
            "tecnico": {
                "id": incidente.tecnico.id,
                "nombre_completo": incidente.tecnico.nombre_completo,
                "telefono": incidente.tecnico.telefono,
                "esta_disponible": incidente.tecnico.esta_disponible,
            } if incidente.tecnico else None,
            "historial": [
                {
                    "id": item.id,
                    "estado_anterior": item.estado_anterior,
                    "estado_nuevo": item.estado_nuevo,
                    "tipo_actor": item.tipo_actor,
                    "id_actor": item.id_actor,
                    "notas": item.notas,
                    "creado_en": item.creado_en,
                }
                for item in incidente.historial
            ] if incidente.historial else [],
            "creado_at": incidente.creado_at,
            "resuelto_at": incidente.resuelto_at,
        }
        return data

    async def _guardar_historial(
        self,
        incidente_id: int,
        estado_anterior: Optional[str],
        estado_nuevo: str,
        tipo_actor: str,
        id_actor: Optional[int] = None,
        notas: Optional[str] = None,
    ) -> None:
        historial = HistorialEstado(
            incidente_id=incidente_id,
            estado_anterior=estado_anterior,
            estado_nuevo=estado_nuevo,
            tipo_actor=tipo_actor,
            id_actor=id_actor,
            notas=notas,
        )
        self.repo.db.add(historial)
        await self.repo.db.flush()

    async def crear(self, data: IncidenteCreate, usuario_id: int) -> dict:
        incidente = await self.repo.crear(data, usuario_id)
        await self._guardar_historial(
            incidente.id,
            estado_anterior=None,
            estado_nuevo=incidente.estado,
            tipo_actor="usuario",
            id_actor=usuario_id,
            notas="Incidente creado",
        )
        coordenadas = await self.repo.obtener_coordenadas(incidente.id)
        return self._serializar(incidente, coordenadas)

    async def obtener_por_id(self, incidente_id: int) -> dict:
        incidente = await self.repo.obtener_por_id(incidente_id)
        if not incidente:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Incidente {incidente_id} no encontrado",
            )
        coordenadas = await self.repo.obtener_coordenadas(incidente_id)
        return self._serializar(incidente, coordenadas)

    async def listar_por_usuario(self, usuario_id: int) -> list[dict]:
        incidentes = await self.repo.listar_por_usuario(usuario_id)
        resultado = []
        for inc in incidentes:
            coord = await self.repo.obtener_coordenadas(inc.id)
            resultado.append(self._serializar(inc, coord))
        return resultado

    async def listar_todos(self, estado: Optional[str] = None) -> list[dict]:
        incidentes = await self.repo.listar_todos(estado)
        resultado = []
        for inc in incidentes:
            coord = await self.repo.obtener_coordenadas(inc.id)
            resultado.append(self._serializar(inc, coord))
        return resultado

    async def actualizar(self, incidente_id: int, data: IncidenteUpdate) -> dict:
        await self.obtener_por_id(incidente_id)
        incidente = await self.repo.actualizar(incidente_id, data)
        coordenadas = await self.repo.obtener_coordenadas(incidente_id)
        return self._serializar(incidente, coordenadas)

    async def cambiar_estado(self, incidente_id: int, estado: str) -> dict:
        incidente_actual = await self.repo.obtener_por_id(incidente_id)
        if not incidente_actual:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Incidente {incidente_id} no encontrado",
            )
        estado_anterior = incidente_actual.estado
        EstadoIncidenteValidator.validar_transicion(estado_anterior, estado)
        incidente = await self.repo.cambiar_estado(incidente_id, estado)
        await self._guardar_historial(
            incidente_id=incidente_id,
            estado_anterior=estado_anterior,
            estado_nuevo=estado,
            tipo_actor="sistema",
            notas=f"Estado cambiado de {estado_anterior} a {estado}",
        )
        coordenadas = await self.repo.obtener_coordenadas(incidente_id)
        return self._serializar(incidente, coordenadas)

    async def eliminar(self, incidente_id: int) -> dict:
        await self.obtener_por_id(incidente_id)
        await self.repo.eliminar(incidente_id)
        return {"mensaje": f"Incidente {incidente_id} eliminado"}