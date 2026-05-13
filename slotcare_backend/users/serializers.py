from rest_framework import serializers
from .models import CustomUser, Missatge
from .validators import SlotCarePasswordValidator
from .models import SesionJuego
from .models import Noticia

class CustomUserSerializer(serializers.ModelSerializer):
    # ... (aquest serialitzador és per a la gestió CRUD, no per al registre)
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'rol', 'esta_bloquejat', 'comptador_intents_fallits']
        read_only_fields = ['comptador_intents_fallits'] 
        

class UserCreationSerializer(serializers.ModelSerializer):
    """Serialitzador per a la creació d'usuaris (Requisit 1)."""
    password = serializers.CharField(
        write_only=True, 
        required=True, 
        style={'input_type': 'password'},
        validators=[SlotCarePasswordValidator()] # Apliquem el validador estricte
    )
    
    class Meta:
        model = CustomUser
        fields = ['username', 'email', 'first_name', 'last_name', 'password', 'rol']
        extra_kwargs = {
            # Assegurem que aquests camps siguin obligatoris.
            'first_name': {'required': True}, 
            'last_name': {'required': True}, 
            'rol': {'required': False, 'default': 'Client'},
        }

    def create(self, validated_data):
        # Aquesta crida ha de ser correcta i utilitzar totes les dades.
        user = CustomUser.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            rol=validated_data.get('rol', 'Client') 
        )
        return user

class SesionJuegoSerializer(serializers.ModelSerializer):
    class Meta:
        model = SesionJuego
        fields = ['duracion_segundos', 'perdida_estimada']

    def create(self, validated_data):
        # El usuario lo sacaremos del token, no del JSON por seguridad
        validated_data['usuario'] = self.context['request'].user
        return super().create(validated_data)


class NoticiaSerializer(serializers.ModelSerializer): #creo el serializer de noticia amb TOTES les dades
    class Meta:
        model = Noticia
        fields = '__all__'

class MissatgeSerializer(serializers.ModelSerializer):
    # afegeixo els camps de lectura per veure el nom d'usuari directament
    emisor_username = serializers.ReadOnlyField(source='emisor.username')
    receptor_username = serializers.ReadOnlyField(source='receptor.username')

    class Meta:
        model = Missatge
        fields = [
            'id', 
            'emisor', 
            'emisor_username', 
            'receptor', 
            'receptor_username', 
            'contenido', 
            'fecha_envio', 
            'leido'
        ]
        # L'emisor el posare des de la vista segons l'usuari loguejat
        read_only_fields = ['emisor', 'fecha_envio']

class UserSerializer(serializers.ModelSerializer): #em servira perque el terapeuta pugui veure una llista dels pacients amb els que te missatges
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'first_name', 'last_name']