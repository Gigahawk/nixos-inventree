import json
import os
import sys
# This is required to pickup InvenTree.settings for some reason
sys.path.append(os.getcwd())

import django
from django.db import transaction
from django.db.utils import IntegrityError

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'InvenTree.settings')
django.setup()

from django.contrib.auth import get_user_model

def _get_user_data():
    if os.isatty(0):
        print("No user data piped in, exiting")
        exit(1)
    _data = sys.stdin.read()
    try:
        data = json.loads(_data)
    except json.decoder.JSONDecodeError:
        print(f"Error parsing user data json:\n{_data}")
        exit(1)
    for username, fields in data.items():
        email = fields["email"]
        password_file = fields["password_file"]
        print(
            f"Reading password file for {username} ({email}) "
            f"from {password_file}")
        with open(password_file, "r") as f:
            # Strip leading/trailing whitespace from password
            fields["password"] = f.read().strip()
    # TODO: REMOVE THIS
    print(data)
    return data


def _commit_users(data):
    user_model = get_user_model()
    try:
        with transaction.atomic():
            print("Deleting all users")
            all_users = user_model.objects.all()
            print(all_users)
            all_users.delete()

            for username, fields in data.items():
                password = fields["password"]
                email = fields["email"]
                is_superuser = fields.get("is_superuser", False)
                # can we use kwargs to do this?
                if is_superuser:
                    print(f"Creating superuser {username}")
                    new_user = user_model.objects.create_superuser(
                        username, email, password
                    )
                    print(f"User {new_user} was created!")
                else:
                    print(f"Creating regular user {username}")
                    new_user = user_model.objects.create_user(
                        username, email, password
                    )
                    print(f"User {new_user} was created!")
    except IntegrityError:
        print("integrity error")


def main():
    data = _get_user_data()
    _commit_users(data)

if __name__ == "__main__":
    main()

