import {
  getLibraryApi, getLibraryItemApi, createLibraryItemApi,
  updateLibraryItemApi, deleteLibraryItemApi,
  searchLibraryApi, getPopularLibraryApi, downloadLibraryItemApi,
} from '../api/library.api.js';
import { addErrorToast, addSuccessToast } from '../state/ui.store.js';

export async function loadLibrary(page = 0, size = 20) {
  try {
    return await getLibraryApi(page, size);
  } catch (e) {
    addErrorToast('Erro ao carregar biblioteca');
    throw e;
  }
}

export async function loadLibraryItem(id) {
  try {
    return await getLibraryItemApi(id);
  } catch (e) {
    addErrorToast('Erro ao carregar item');
    throw e;
  }
}

export async function createLibraryItem(data) {
  try {
    const result = await createLibraryItemApi(data);
    addSuccessToast('Material adicionado!');
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function updateLibraryItem(id, data) {
  try {
    const result = await updateLibraryItemApi(id, data);
    addSuccessToast('Material atualizado!');
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function deleteLibraryItem(id) {
  try {
    await deleteLibraryItemApi(id);
    addSuccessToast('Material excluído');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function searchLibrary(query, type = '', page = 0) {
  try {
    return await searchLibraryApi(query, type, page);
  } catch (e) {
    addErrorToast('Erro na busca');
    throw e;
  }
}

export async function loadPopularLibrary(page = 0) {
  try {
    return await getPopularLibraryApi(page);
  } catch (e) {
    addErrorToast('Erro ao carregar populares');
    throw e;
  }
}
