from django.shortcuts import render
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.template.loader import render_to_string
from django.core.mail import send_mail
from django.conf import settings
from users.models import User
from django.urls import reverse


def reset_password_request(request):
    if request.method == 'POST':
        email = request.POST.get('email')
        user = User.objects.filter(email=email).first()
        if user:
            uid = urlsafe_base64_encode(force_bytes(user.id))
            token = default_token_generator.make_token(user)
            reset_url = reverse(
                "api:reset_password_confirm",
                kwargs={"uidb64": uid, "token": token}
            )
            reset_link = request.build_absolute_uri(reset_url)
            message = render_to_string(
                "password_forms/reset_email.html",
                {
                    "user": user,
                    "reset_link": reset_link,
                }
            )
            send_mail(
                "Сброс пароля",
                message,
                settings.DEFAULT_FROM_EMAIL,
                [email],
                fail_silently=False,
            )
        return render(request, "password_forms/email_sent.html")
    return render(request, "password_forms/reset_form.html")


def reset_password_confirm(request, uidb64, token):
    try:
        uid = force_str(urlsafe_base64_decode(uidb64))
        user = User.objects.get(id=int(uid))
    except Exception:
        user = None

    if user and default_token_generator.check_token(user, token):
        if request.method == 'POST':
            new_password = request.POST.get('new_password2')
            if new_password:
                user.set_password(new_password)
                user.save()
                return render(request, "password_forms/reset_success.html")
        return render(
            request,
            "password_forms/reset_confirm.html",
            {"valid_link": True})
    else:
        return render(
            request,
            "password_forms/reset_confirm.html",
            {"valid_link": False}
        )
