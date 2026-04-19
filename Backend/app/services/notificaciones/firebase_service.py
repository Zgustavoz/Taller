import firebase_admin
from firebase_admin import credentials, messaging
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)
_inicializado = False


def inicializar_firebase():
    global _inicializado
    if not _inicializado:
        try:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred)
            _inicializado = True
            logger.info("✅ Firebase inicializado")
        except Exception as e:
            logger.error(f"❌ Error Firebase: {e}")


async def enviar_a_token(
    token: str,
    titulo: str,
    cuerpo: str,
    datos: dict | None = None,
) -> bool:
    inicializar_firebase()
    try:
        msg = messaging.Message(
            notification=messaging.Notification(title=titulo, body=cuerpo),
            data={k: str(v) for k, v in (datos or {}).items()},
            token=token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    sound="default",
                    color="#4F46E5",
                ),
            ),
        )
        messaging.send(msg)
        return True
    except Exception as e:
        logger.error(f"Error FCM token: {e}")
        return False


async def enviar_a_multiples(
    tokens: list[str],
    titulo: str,
    cuerpo: str,
    datos: dict | None = None,
) -> dict:
    inicializar_firebase()
    if not tokens:
        return {"exitosos": 0, "fallidos": 0}
    try:
        msg = messaging.MulticastMessage(
            notification=messaging.Notification(title=titulo, body=cuerpo),
            data={k: str(v) for k, v in (datos or {}).items()},
            tokens=tokens,
            android=messaging.AndroidConfig(priority="high"),
        )
        res = messaging.send_each_for_multicast(msg)
        return {"exitosos": res.success_count, "fallidos": res.failure_count}
    except Exception as e:
        logger.error(f"Error FCM multicast: {e}")
        return {"exitosos": 0, "fallidos": len(tokens)}