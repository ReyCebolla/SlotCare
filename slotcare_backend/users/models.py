from django.db import models
from django.contrib.auth.models import AbstractUser

# Tipus de Rol (Requisit 3)
ROL_OPCIONS = (
    ('Superadmin', 'Superadministrador'),
    ('Admin', 'Administrador'),
    ('Terapeuta', 'Terapeuta'),
    ('Client', 'Usuari Final o Client'),
)

class CustomUser(AbstractUser):
    """Model d'usuari personalitzat per SlotCare (Gestió d'Usuaris)."""
    
    # AbstractUser ja proporciona: username, email, first_name, last_name, password
    
    rol = models.CharField(
        max_length=20,
        choices=ROL_OPCIONS,
        default='Client',
        verbose_name='Rol'
    )
    
    # Camps per a Bloqueig i Autenticació (Requisits 2 i 5)
    comptador_intents_fallits = models.IntegerField(default=0, verbose_name='Intents Fallits')
    esta_bloquejat = models.BooleanField(default=False, verbose_name='Bloquejat')
    
    class Meta:
        verbose_name = 'Usuari'
        verbose_name_plural = 'Usuaris'

    def __str__(self):
        return self.username
    
    def desbloquejar_compte(self):
        """Mètode per desbloquejar i resetejar el comptador (Requisit 5)."""
        self.esta_bloquejat = False
        self.comptador_intents_fallits = 0
        self.save()

class Noticia(models.Model): #aqui he creaat la clase noticia per tenir la taula per anar afegint noticies, important!!!! poso la data de publicacio per ordenarles al mostrarles
    titol = models.CharField(max_length=200)
    contingut = models.TextField()
    imatge_url = models.URLField(blank=True, null=True) 
    data_publicacio = models.DateTimeField(auto_now_add=True)
    font = models.CharField(max_length=100, blank=True) 

    def __clau__(self):
        return self.titol

class Missatge(models.Model):
    emisor = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='mensajes_enviados')
    receptor = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='mensajes_recibidos')
    contenido = models.TextField()
    fecha_envio = models.DateTimeField(auto_now_add=True)
    leido = models.BooleanField(default=False)

    class Meta:
        ordering = ['fecha_envio']

    def __str__(self):
        return f"De {self.emisor.username} a {self.receptor.username} - {self.fecha_envio}"

class RegistreSessio(models.Model):
    """Model per comptabilitzar inicis de sessió (Requisit 4)."""
    
    username = models.CharField(max_length=150)
    data_hora = models.DateTimeField(auto_now_add=True)
    sistema = models.CharField(max_length=50) # Origen (Web/Android/Flutter)
    inici_correcte = models.BooleanField(default=False)
    raó_fallida = models.TextField(null=True, blank=True)
    
    class Meta:
        verbose_name = 'Registre de Sessió'
        verbose_name_plural = 'Registres de Sessions'
        ordering = ['-data_hora']

    def __str__(self):
        return f"[{self.data_hora.strftime('%Y-%m-%d %H:%M')}] {self.username} - {'OK' if self.inici_correcte else 'FAIL'}"
    

class SesionJuego(models.Model):
    usuario = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='sesiones')
    fecha_inicio = models.DateTimeField(auto_now_add=True)
    duracion_segundos = models.IntegerField()
    # Para el requisito de pérdidas hipotéticas que mencionamos antes
    perdida_estimada = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)

    def __str__(self):
        return f"Sesión de {self.usuario.username} - {self.duracion_segundos}s"