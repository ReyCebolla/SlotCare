from django.urls import path, include, re_path
from rest_framework.routers import DefaultRouter
from .views import LoginView, RegisterClientView, UserManagementViewSet, guardar_sesion_juego, llista_noticies, MissatgeViewSet, llista_terapeutes


# Router per a les vistes de gestió d'usuaris (CRUD)
router = DefaultRouter()
router.register(r'gestion', UserManagementViewSet, basename='gestion')
router.register(r'missatges', MissatgeViewSet, basename='missatge') 


urlpatterns = [
    # Rutes d'Autenticació: 
    # Utilitzem re_path amb el símbol '?' al final per fer la barra obliqua opcional.
    re_path(r'^register/?$', RegisterClientView.as_view(), name='register_client'), 
    re_path(r'^login/?$', LoginView.as_view(), name='api_login'),
    path('guardar-sesion/', guardar_sesion_juego, name='guardar-sesion'),
    path('noticies/', llista_noticies, name='llista_noticies'),
    path('terapeutes-llista/', llista_terapeutes, name='llista_terapeutes'),

    
    # Rutes de Gestió d'Usuaris i missatges
    path('', include(router.urls)), 
]