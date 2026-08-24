import httpx
import logging
from app.core.config import settings
import io
import mimetypes
import struct

logger = logging.getLogger(__name__)

class TranscriptionService:
    def __init__(self):
        self.api_key = settings.GROQ_API_KEY
        self.url = "https://api.groq.com/openai/v1/audio/transcriptions"

    def _add_wav_header(self, pcm_data: bytes, sample_rate: int = 16000) -> bytes:
        """Adiciona um cabeçalho WAV (RIFF) a dados PCM brutos."""
        header = struct.pack('<4sI4s', b'RIFF', len(pcm_data) + 36, b'WAVE')
        fmt_chunk = struct.pack('<4sIHHIIHH', b'fmt ', 16, 1, 1, sample_rate, sample_rate * 2, 2, 16)
        data_chunk = struct.pack('<4sI', b'data', len(pcm_data))
        return header + fmt_chunk + data_chunk + pcm_data

    async def transcribe_audio(self, audio_bytes: bytes, filename: str = "audio.ogg") -> str:
        """Transcreve áudio usando a API do Groq (Whisper)."""
        if not self.api_key:
            logger.warning("GROQ_API_KEY não configurada.")
            return "[Erro: Transcrição indisponível]"

        if not audio_bytes or len(audio_bytes) < 100:
            return "[Áudio muito curto]"

        try:
            # 1. Identificar formato e preparar bytes
            mime_type = "audio/mpeg"
            if filename.endswith(".raw"):
                logger.info(f"Convertendo PCM ({len(audio_bytes)} bytes) para WAV...")
                audio_bytes = self._add_wav_header(audio_bytes)
                mime_type = "audio/wav"
                filename = filename.replace(".raw", ".wav")
            elif filename.endswith(".wav"):
                mime_type = "audio/wav"
            elif filename.endswith(".webm"):
                mime_type = "audio/webm"
            elif filename.endswith(".m4a"):
                mime_type = "audio/mp4"
            else:
                mime_type, _ = mimetypes.guess_type(filename)
                mime_type = mime_type or "audio/mpeg"

            # 2. Chamar API
            logger.info(f"Enviando para Groq: {filename} ({mime_type}) - {len(audio_bytes)} bytes")
            
            files = {
                "file": (filename, io.BytesIO(audio_bytes), mime_type),
                "model": (None, "whisper-large-v3"),
                "language": (None, "pt")
            }

            headers = {"Authorization": f"Bearer {self.api_key}"}
            
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(self.url, headers=headers, files=files)
                response.raise_for_status()
                result = response.json()
                logger.info(f"Resposta Groq Raw: {result}")
                transcription = result.get("text", "").strip()
                
                # Filtrar alucinações de silêncio
                silent_phrases = ["Legenda por", "Subtitles by", "Obrigado por assistir", "Música"]
                if not transcription or any(p in transcription for p in silent_phrases):
                    return ""
                    
                return transcription

        except Exception as e:
            logger.error(f"Falha na transcrição: {e}")
            return f"[Erro na transcrição: {str(e)}]"

transcription_service = TranscriptionService()
