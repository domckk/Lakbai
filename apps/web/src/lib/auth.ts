import { apiClient } from './api-client';
import type { AuthUser } from './store';

export async function loginApi(email: string, password: string): Promise<{ accessToken: string; refreshToken: string; user: { id: string; email: string; role: string } }> {
  const { data } = await apiClient.post('/auth/login', { email, password });
  if (typeof window !== 'undefined') {
    localStorage.setItem('access_token', data.accessToken);
    localStorage.setItem('refresh_token', data.refreshToken);
  }
  return data;
}

export async function registerApi(email: string, username: string, password: string): Promise<{ accessToken: string; refreshToken: string; user: { id: string; email: string; role: string } }> {
  const { data } = await apiClient.post('/auth/register', { email, username, password });
  if (typeof window !== 'undefined') {
    localStorage.setItem('access_token', data.accessToken);
    localStorage.setItem('refresh_token', data.refreshToken);
  }
  return data;
}

export async function getCurrentUser(): Promise<AuthUser> {
  const { data } = await apiClient.get('/me');
  return data;
}
