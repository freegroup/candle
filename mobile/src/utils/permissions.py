from plyer.utils import platform
from utils.storage import Storage

def _required_permissions():
    if platform == "android":
        from android.permissions import Permission
        return [Permission.BLUETOOTH_SCAN,  Permission.BLUETOOTH, Permission.BLUETOOTH_CONNECT, Permission.ACCESS_COARSE_LOCATION, Permission.ACCESS_FINE_LOCATION]
    
    return []

def has_all_permissions():
    if platform == "android":
        from android.permissions import check_permission
        return check_permission(_required_permissions())
    
    return Storage.get("permissions")!=None



def ask_all_permission():
    if platform == "android":
        from android.permissions import request_permissions
        request_permissions(_required_permissions())
    else:
        Storage.set("permissions", "granted")