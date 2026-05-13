from rest_framework import viewsets, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework import permissions
from django.contrib.auth import authenticate
from django.db import transaction
from .models import CustomUser, Missatge, RegistreSessio
from .serializers import CustomUserSerializer, MissatgeSerializer, UserCreationSerializer, UserSerializer
from .permissions import CanManageUsers
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .serializers import SesionJuegoSerializer, NoticiaSerializer, MissatgeSerializer
from rest_framework.authtoken.models import Token
from .models import CustomUser, SesionJuego, Noticia
from rest_framework import status, permissions # Assegura't que tens 'permissions'
from rest_framework.permissions import AllowAny, IsAuthenticated # Afegeix AllowAny aquí
from django.db.models import Q

MAX_INTENTS = 3

# --- AUTENTICACIÓ I REGISTRE ---

class RegisterClientView(APIView):
    """Permet el registre d'un nou Client (Usuari Final - Requisit 3)."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = UserCreationSerializer(data=request.data)
        
        try:
            if serializer.is_valid(raise_exception=True):
                # Aquesta línia hauria de forçar el rol a Client
                serializer.validated_data['rol'] = 'Client' 
                user = serializer.save()
                return Response({"message": "Compte de client creat correctament.", "username": user.username}, status=status.HTTP_201_CREATED)
            
        except Exception as e:
             # Retorn de seguretat en cas d'excepció no capturada
             return Response({"error": "Error intern del servidor al registrar." , "details": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
             
        # Si la validació falla, DRF retorna el 400 amb JSON
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    """Gestió de l'inici de sessió, bloqueig i registre (Requisits 2, 4, 5)."""
    permission_classes = [permissions.AllowAny]
    
    @transaction.atomic
    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        sistema = request.data.get('sistema', 'Flutter App') 

        try:
            user = CustomUser.objects.get(username=username)
        except CustomUser.DoesNotExist:
            RegistreSessio.objects.create(
                username=username, sistema=sistema, inici_correcte=False, raó_fallida="Usuari inexistent"
            )
            return Response({"error": "Nom d'usuari o contrasenya invàlids."}, status=status.HTTP_401_UNAUTHORIZED)
            
        # 1. Comprovar bloqueig (Requisit 5)
        if user.esta_bloquejat:
            RegistreSessio.objects.create(
                username=username, sistema=sistema, inici_correcte=False, raó_fallida="Compte bloquejat per intents fallits"
            )
            # Missatge de bloqueig requerit (Requisit 2.2)
            return Response({"error": f"{MAX_INTENTS} intents d'inici de sessió incorrectes. El compte està bloquejat."}, status=status.HTTP_403_FORBIDDEN)
            
        # 2. Autenticació
        authenticated_user = authenticate(username=username, password=password)
        
        if authenticated_user is not None:
            # Login CORRECTE (Requisit 4)
            user.comptador_intents_fallits = 0
            user.save()
            
            token, created = Token.objects.get_or_create(user=user)
            RegistreSessio.objects.create(
                username=username, sistema=sistema, inici_correcte=True
            )
            return Response({
                "message": "Inici de sessió correcte.", 
                "rol": user.rol,
                'user_id': user.id,
                "token": token.key  # Enviem la clau del token de la base de dades
            }, status=status.HTTP_200_OK)
        else:
            # Login FALLIT (Requisit 2, 4, 5)
            user.comptador_intents_fallits += 1
            raó = "Contrasenya incorrecta"
            
            # 3. Bloqueig per intents fallits
            if user.comptador_intents_fallits >= MAX_INTENTS:
                user.esta_bloquejat = True
                raó += f". Compte bloquejat (>{MAX_INTENTS} intents)."
                
            user.save()
            
            RegistreSessio.objects.create(
                username=username, sistema=sistema, inici_correcte=False, raó_fallida=raó
            )
            
            if user.esta_bloquejat:
                return Response({"error": f"{MAX_INTENTS} intents d'inici de sessió incorrectes. El compte està bloquejat."}, 
                                status=status.HTTP_403_FORBIDDEN)
            else:
                return Response({"error": "Nom d'usuari o contrasenya invàlids."}, status=status.HTTP_401_UNAUTHORIZED)


# --- GESTIÓ D'USUARIS (RBAC) ---

class UserManagementViewSet(viewsets.ModelViewSet):
    """Gestiona la creació, modificació, eliminació i consulta d'usuaris (Requisits 1, 3)."""
    serializer_class = CustomUserSerializer
    permission_classes = [CanManageUsers]
    queryset = CustomUser.objects.all()
    
    def get_serializer_class(self):
        if self.action == 'create':
            return UserCreationSerializer
        return CustomUserSerializer

    def get_queryset(self):
        # Filtre per al Client, Admin i Superadmin (Requisit 3)
        user = self.request.user
        if user.rol == 'Client':
            return self.queryset.filter(pk=user.pk) # Només es veu a si mateix
        
        if user.rol == 'Admin':
            return self.queryset.filter(rol='Client') # Només veu Clients
            
        return self.queryset # Superadmin veu tots

    def perform_create(self, serializer):
        # Lògica RBAC per crear usuaris (Admin només pot fer Clients)
        rol_assignat = self.request.data.get('rol', 'Client')
        
        if self.request.user.rol == 'Admin' and rol_assignat != 'Client':
            # Això hauria de llençar un error 403 (Forbidden)
            # IMPORTANT: En perform_create hem de retornar una Response directa si el permís falla
            return Response({"error": "L'Administrador només pot donar d'alta Clients."}, 
                           status=status.HTTP_403_FORBIDDEN)
        
        # Si els permisos passen, creem l'usuari amb la contrasenya xifrada
        user = CustomUser.objects.create_user(
            username=serializer.validated_data['username'],
            email=serializer.validated_data['email'],
            password=serializer.validated_data['password'],
            first_name=serializer.validated_data['first_name'],
            last_name=serializer.validated_data['last_name'],
            rol=rol_assignat
        )


    @action(detail=True, methods=['post'], permission_classes=[CanManageUsers])
    def desbloquejar(self, request, pk=None):
        """Endpoint per desbloquejar un compte (Requisit 5)."""
        try:
            user_a_desbloquejar = CustomUser.objects.get(pk=pk)
        except CustomUser.DoesNotExist:
            return Response({"error": "Usuari no trobat."}, status=status.HTTP_404_NOT_FOUND)
            
        # Comprovació de permisos (Admin només pot desbloquejar Clients)
        if request.user.rol == 'Admin' and user_a_desbloquejar.rol != 'Client':
            return Response({"error": "L'Administrador només pot desbloquejar Clients."}, status=status.HTTP_403_FORBIDDEN)
            
        if user_a_desbloquejar.esta_bloquejat:
            user_a_desbloquejar.desbloquejar_compte() 
            return Response({"message": f"Compte de '{user_a_desbloquejar.username}' desbloquejat i intents resetejats."}, 
                            status=status.HTTP_200_OK) # <--- Hem completat el tancament aquí
        
        return Response({"message": "El compte ja estava desbloquejat."}, status=status.HTTP_200_OK)
    

# Gestio de sessions de joc
@api_view(['GET', 'POST']) #al principio puse solo push pero he añadido el get para mostrar la tabla de sesiones
@permission_classes([IsAuthenticated])
def guardar_sesion_juego(request):
    if request.method == 'GET':
        # busco todas las sesiones del usuario que inciia sesion
        sesiones = SesionJuego.objects.filter(usuario=request.user).order_by('-id')
        serializer = SesionJuegoSerializer(sesiones, many=True)
        return Response(serializer.data)
    serializer = SesionJuegoSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        serializer.save()
        return Response({'status': 'Sesión guardada correctamente'}, status=201)
    return Response(serializer.errors, status=400)


@api_view(['GET'])
@permission_classes([AllowAny]) # poso que tothom pot llegir les noticies, no necessitem autenticacio de cap tipus
def llista_noticies(request):
    noticies = Noticia.objects.all().order_by('-data_publicacio')
    serializer = NoticiaSerializer(noticies, many=True)
    return Response(serializer.data)

class MissatgeViewSet(viewsets.ModelViewSet):
    serializer_class = MissatgeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Retorna missatges on l'usuari és emisor o receptor
        return Missatge.objects.filter(Q(emisor=user) | Q(receptor=user))

    def perform_create(self, serializer):
        # L'emisor sempre és l'usuari que fa la petició
        serializer.save(emisor=self.request.user)

#he hagut de crear aquest endpoint per accedir a la llista de terapeutes
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def llista_terapeutes(request):
    # busco nomes els usuaris amb rol 'Terapeuta'
    terapeutes = CustomUser.objects.filter(rol='Terapeuta')
    serializer = UserSerializer(terapeutes, many=True)
    return Response(serializer.data)