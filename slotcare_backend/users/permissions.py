from rest_framework import permissions

class CanManageUsers(permissions.BasePermission):
    """Permís per consultar/modificar/eliminar usuaris segons el seu rol (RBAC).
    
    Implementa les regles següents (Requisit 3):
    - Client: Només pot actuar sobre el seu propi compte.
    - Administrador: Només pot actuar sobre usuaris de rol 'Client'.
    - Superadministrador: Pot actuar sobre qualsevol usuari.
    """
    message = "No tens permís per realitzar aquesta operació sobre aquest usuari o rol."

    def has_permission(self, request, view):
        # Tots els usuaris han d'estar autenticats per usar el ViewSet de gestió
        return request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        # (obj) és l'usuari que s'intenta modificar, consultar o eliminar. 
        # (request.user) és qui fa la petició.
        
        # 1. USUARI FINAL O CLIENT (Només pot actuar sobre si mateix)
        if request.user.rol == 'Client':
            return obj == request.user

        # 2. ADMINISTRADOR (Només pot modificar Clients)
        elif request.user.rol == 'Admin':
            # Pot veure/modificar/eliminar Clients
            if obj.rol == 'Client':
                return True
            # No pot tocar altres Admins o Superadmins
            return False
            
        # 3. SUPERADMINISTRADOR (Pot fer qualsevol operació)
        elif request.user.rol == 'Superadmin':
            return True
            
        return False