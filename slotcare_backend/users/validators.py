import re
from django.core.exceptions import ValidationError

class SlotCarePasswordValidator(object): # <-- Afegim (object) per seguretat
    """
    Requisit 2: La contrasenya ha de contenir:
    - Mínim 8 caràcters
    - Almenys una majúscula, una minúscula, un número i un símbol dels especificats.
    """
    
    def validate(self, password, user=None):
        # 1. Longitud mínima
        if len(password) < 8:
            raise ValidationError(
                ("La contrasenya ha de contenir almenys 8 caràcters."),
                code='password_min_length',
            )

        # 2. Majúscula, minúscula, número i símbol
        if not re.search(r'[A-Z]', password):
            raise ValidationError(
                ("La contrasenya ha de contenir almenys una lletra majúscula."),
                code='password_no_uppercase',
            )
        if not re.search(r'[a-z]', password):
            raise ValidationError(
                ("La contrasenya ha de contenir almenys una lletra minúscula."),
                code='password_no_lowercase',
            )
        if not re.search(r'\d', password):
            raise ValidationError(
                ("La contrasenya ha de contenir almenys un número."),
                code='password_no_digit',
            )
            
        # 3. Símbols requerits: $;._-*
        if not re.search(r'[\$;\.\-_*]', password):
            raise ValidationError(
                ("La contrasenya ha de contenir almenys un símbol entre $, ;, ., _, - o *."),
                code='password_no_symbol',
            )
        
    def get_help_text(self):
        return (
            "La contrasenya ha de complir: 8 caràcters, majúscula, minúscula, número i un símbol ($, ;, ., _, -, *)."
        )
        
    # AFEGIM AQUEST MÈTODE PER ASSEGURAR QUE SIGUI CRIDABLE EN CONTEXTOS AMBIGUS
    def __call__(self, value):
        return self.validate(value)