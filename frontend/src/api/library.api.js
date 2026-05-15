import { get, post, put, del } from './client';
import { LIBRARY } from '../constants/api';

export function getLibraryApi(params) {
  return get(LIBRARY.LIST, { params });
}

export function getLibraryItemApi(id) {
  return get(LIBRARY.BY_ID(id));
}

export function createLibraryItemApi(body) {
  return post(LIBRARY.CREATE, { body });
}

export function updateLibraryItemApi(id, body) {
  return put(LIBRARY.UPDATE(id), { body });
}

export function deleteLibraryItemApi(id) {
  return del(LIBRARY.DELETE(id));
}

export function searchLibraryApi(params) {
  return get(LIBRARY.SEARCH, { params });
}

export function getPopularLibraryApi() {
  return get(LIBRARY.POPULAR);
}

export function downloadLibraryItemApi(id) {
  return get(LIBRARY.DOWNLOAD(id));
}
