import { get, post, put, del } from './client.js';
import { LIBRARY } from '../constants/api.js';

export function getLibraryApi(page = 0, size = 20) {
  return get(LIBRARY.LIST, { params: { page, size } });
}

export function getLibraryItemApi(id) {
  return get(LIBRARY.BY_ID(id));
}

export function createLibraryItemApi(data) {
  return post(LIBRARY.CREATE, { body: data });
}

export function updateLibraryItemApi(id, data) {
  return put(LIBRARY.UPDATE(id), { body: data });
}

export function deleteLibraryItemApi(id) {
  return del(LIBRARY.DELETE(id));
}

export function searchLibraryApi(query, type, page = 0, size = 20) {
  return get(LIBRARY.SEARCH, { params: { query, type, page, size } });
}

export function getPopularLibraryApi(page = 0, size = 20) {
  return get(LIBRARY.POPULAR, { params: { page, size } });
}

export function downloadLibraryItemApi(id) {
  return get(LIBRARY.DOWNLOAD(id));
}
