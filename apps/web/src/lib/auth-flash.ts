export const AUTH_FLASH_KEY = 'beelectric_auth_flash';

export function setAuthFlash(message: string): void {
  if (typeof sessionStorage === 'undefined') return;
  sessionStorage.setItem(AUTH_FLASH_KEY, message);
}

export function consumeAuthFlash(): string | null {
  if (typeof sessionStorage === 'undefined') return null;
  const message = sessionStorage.getItem(AUTH_FLASH_KEY);
  if (message) sessionStorage.removeItem(AUTH_FLASH_KEY);
  return message;
}
