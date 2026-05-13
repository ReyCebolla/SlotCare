from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, Missatge, RegistreSessio, Noticia

# Registrem el model de registre de sessions
admin.site.register(RegistreSessio)

# Personalització del panell de l'usuari (Requisit 3 i 5)
class CustomUserAdmin(UserAdmin):
    """
    Personalitza el model d'usuari al panell d'administració 
    per mostrar el Rol, el comptador d'intents i l'estat de bloqueig.
    """
    model = CustomUser
    # Columnes visibles a la llista d'usuaris
    list_display = ['username', 'email', 'rol', 'is_staff', 'esta_bloquejat', 'comptador_intents_fallits']
    
    # Camps addicionals visibles a la vista de detall d'usuari
    fieldsets = UserAdmin.fieldsets + (
        ('Informació de SlotCare', {'fields': ('rol', 'esta_bloquejat', 'comptador_intents_fallits')}),
    )
    # Filtres laterals per a la llista
    list_filter = ['rol', 'esta_bloquejat', 'is_staff']

# Registrem el nostre model d'usuari personalitzat amb la nostra configuració
admin.site.register(CustomUser, CustomUserAdmin)

class NoticiaAdmin(admin.ModelAdmin):
    list_display = ['titol', 'font', 'data_publicacio']
    search_fields = ['titol', 'contingut']

admin.site.register(Noticia, NoticiaAdmin)
admin.site.register(Missatge)