from datetime import datetime
from app.models.appointment import Appointment
from app.models.patient import Patient
from app.models.medico import Medico

class PrescriptionService:
    def generate_html(self, appointment: Appointment, patient: Patient, medico: Medico = None) -> str:
        patient_name = patient.name
        patient_dob = patient.date_of_birth.strftime("%d/%m/%Y") if patient.date_of_birth else "Não informada"
        from datetime import timedelta
        # Ajusta para Horário de Brasília (GMT-3)
        br_time = datetime.utcnow() - timedelta(hours=3)
        prescription_date = br_time.strftime("%d/%m/%Y")
        
        doctor_name = medico.nome_completo if medico else (appointment.doctor.full_name if appointment.doctor else "Médico")
        doc_reg_label = "CRBM"
        doc_reg_value = medico.crm if medico else "Não informado"
        
        prescription_text = appointment.prescription or "Nenhuma medicação prescrita."
        
        # QR Code fake
        qr_code_url = f"https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=VERIFY-PRESCRIPTION-{appointment.id}"
        
        html = f"""
        <!DOCTYPE html>
        <html lang="pt-br">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin: 0; padding: 0; background-color: #f1f5f9; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; color: #1e293b;">
            <div style="max-width: 800px; margin: 20px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.05); border: 1px solid #e2e8f0;">
                
                <!-- Top Accent Bar -->
                <div style="height: 8px; background: linear-gradient(90deg, #2563eb, #3b82f6);"></div>
                
                <div style="padding: 40px;">
                    <!-- Header -->
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 40px; border-bottom: 1px solid #f1f5f9; padding-bottom: 30px;">
                        <div>
                            <h2 style="margin: 0; color: #1e3a8a; font-size: 28px; font-weight: 800; letter-spacing: -0.5px;">OmniConnect</h2>
                            <p style="margin: 4px 0 0 0; color: #64748b; font-size: 12px; text-transform: uppercase; letter-spacing: 1.5px; font-weight: 600;">Intelligent Healthcare</p>
                        </div>
                        <div style="text-align: right;">
                            <h3 style="margin: 0; color: #1e293b; font-size: 18px; font-weight: 700;">{doctor_name}</h3>
                            <p style="margin: 4px 0 0 0; color: #3b82f6; font-size: 14px; font-weight: 600;">{doc_reg_label} {doc_reg_value}</p>
                        </div>
                    </div>

                    <!-- Title -->
                    <div style="text-align: center; margin-bottom: 40px;">
                        <h1 style="margin: 0; color: #1e3a8a; font-size: 32px; font-weight: 800; text-transform: uppercase; letter-spacing: 2px;">Receituário</h1>
                        <div style="width: 50px; height: 4px; background-color: #3b82f6; margin: 12px auto; border-radius: 2px;"></div>
                    </div>

                    <!-- Patient Info -->
                    <div style="background-color: #f8fafc; border-radius: 12px; padding: 24px; margin-bottom: 40px; display: grid; grid-template-columns: 1fr 1fr; gap: 20px; border: 1px solid #e2e8f0;">
                        <div>
                            <span style="display: block; font-size: 11px; color: #64748b; text-transform: uppercase; font-weight: 700; margin-bottom: 4px;">Paciente</span>
                            <span style="font-size: 16px; color: #1e293b; font-weight: 600;">{patient_name}</span>
                        </div>
                        <div style="text-align: right;">
                            <span style="display: block; font-size: 11px; color: #64748b; text-transform: uppercase; font-weight: 700; margin-bottom: 4px;">Data de Nascimento</span>
                            <span style="font-size: 16px; color: #1e293b; font-weight: 600;">{patient_dob}</span>
                        </div>
                        <div style="margin-top: 12px;">
                            <span style="display: block; font-size: 11px; color: #64748b; text-transform: uppercase; font-weight: 700; margin-bottom: 4px;">Data de Emissão</span>
                            <span style="font-size: 16px; color: #1e293b; font-weight: 600;">{prescription_date}</span>
                        </div>
                    </div>

                    <!-- Prescription Box -->
                    <div style="margin-bottom: 40px; min-height: 250px; position: relative;">
                        <h4 style="margin: 0 0 20px 0; color: #1e3a8a; font-size: 16px; font-weight: 700; text-transform: uppercase; display: flex; align-items: center;">
                            <span style="width: 4px; height: 16px; background-color: #3b82f6; display: inline-block; margin-right: 10px; border-radius: 2px;"></span>
                            Medicamentos e Orientações
                        </h4>
                        <div style="font-size: 18px; color: #334155; line-height: 1.8; padding-left: 14px;">
                            {prescription_text}
                        </div>
                    </div>

                    <!-- Agenda / Next Steps -->
                    <div style="background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%); border-radius: 12px; padding: 20px; margin-bottom: 40px; border: 1px solid #bfdbfe;">
                        <h5 style="margin: 0 0 8px 0; color: #1e40af; font-size: 14px; font-weight: 700; display: flex; align-items: center;">
                            📅 Agenda e Próximos Passos
                        </h5>
                        <p style="margin: 0; font-size: 13px; color: #1e3a8a; opacity: 0.8;">
                            Sugerimos acompanhamento às <strong>Terças e Quintas-feiras, das 08:00 às 12:00</strong>.<br>
                            Agende seu retorno diretamente pelo app OmniConnect ou via WhatsApp.
                        </p>
                    </div>

                    <!-- Signature Section -->
                    <div style="display: flex; justify-content: space-between; align-items: flex-end; padding-top: 30px; border-top: 2px solid #f1f5f9;">
                        <div style="text-align: center;">
                            <img src="{qr_code_url}" style="width: 100px; height: 100px; padding: 6px; border: 1px solid #e2e8f0; border-radius: 12px; background: white;" alt="QR Code">
                            <p style="margin: 8px 0 0 0; font-size: 9px; color: #94a3b8; font-weight: 700; text-transform: uppercase; letter-spacing: 1px;">Assinatura Digital</p>
                        </div>
                        <div style="text-align: right; width: 300px;">
                            <div style="border-top: 2px solid #1e3a8a; margin-bottom: 10px;"></div>
                            <p style="margin: 0; font-size: 18px; font-weight: 700; color: #1e293b;">{doctor_name}</p>
                            <p style="margin: 2px 0 0 0; font-size: 13px; color: #64748b; font-weight: 500;">{doc_reg_label} {doc_reg_value}</p>
                        </div>
                    </div>
                </div>

                <!-- Footer -->
                <div style="background-color: #f8fafc; padding: 20px; text-align: center; border-top: 1px solid #e2e8f0;">
                    <p style="margin: 0; font-size: 11px; color: #94a3b8; font-weight: 500;">
                        Este documento é uma prescrição digital válida emitida via OmniConnect Platform.<br>
                        Verificação: {appointment.id}-VERIFY-PR
                    </p>
                </div>
            </div>
        </body>
        </html>
        """
        return html

prescription_service = PrescriptionService()
