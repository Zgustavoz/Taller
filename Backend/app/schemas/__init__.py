from app.schemas.rol_schema import RolCreate, RolUpdate, RolResponse
from app.schemas.usuario_schema import (
    UsuarioCreate, UsuarioUpdate, UsuarioResponse,
    UsuarioConRolesResponse, CambiarPassword
)
from app.schemas.permisos_schema import PermisosCreate, PermisosUpdate, PermisosResponse
from app.schemas.auth_schema import (
    LoginRequest, LoginResponse,
    RecuperarPasswordRequest, ResetPasswordRequest,
    TokenResponse, GoogleCallbackRequest
)
from app.schemas.taller_schema import TallerCreate, TallerUpdate, TallerResponse
