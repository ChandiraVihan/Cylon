#include <windows.h>
#include "notify.h"

void show_notification(const char *title, const char *message) {
    MessageBox(NULL, message, title, MB_OK | MB_ICONINFORMATION);
}