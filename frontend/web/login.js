tailwind.config = {
    darkMode: "class",
    theme: {
        extend: {
            colors: {
                "outline": "#737685",
                "surface-container-high": "#e6e8ea",
                "surface-container-highest": "#e0e3e5",
                "on-tertiary-fixed": "#380d00",
                "on-primary-fixed": "#001848",
                "surface-variant": "#e0e3e5",
                "on-error-container": "#93000a",
                "secondary": "#006c4d",
                "secondary-fixed": "#86f8c8",
                "on-tertiary-container": "#ffc6b2",
                "on-secondary": "#ffffff",
                "background": "#f7f9fb",
                "tertiary": "#7b2600",
                "surface-container-lowest": "#ffffff",
                "surface-container": "#eceef0",
                "error-container": "#ffdad6",
                "on-primary-container": "#c4d2ff",
                "error": "#ba1a1a",
                "secondary-fixed-dim": "#69dbad",
                "on-tertiary-fixed-variant": "#812800",
                "tertiary-fixed-dim": "#ffb59b",
                "surface-container-low": "#f2f4f6",
                "secondary-container": "#86f8c8",
                "on-surface": "#191c1e",
                "surface-bright": "#f7f9fb",
                "on-primary-fixed-variant": "#0040a2",
                "on-background": "#191c1e",
                "inverse-primary": "#b2c5ff",
                "on-error": "#ffffff",
                "inverse-surface": "#2d3133",
                "primary-fixed-dim": "#b2c5ff",
                "on-secondary-container": "#007352",
                "on-surface-variant": "#434654",
                "primary-container": "#0052cc",
                "on-tertiary": "#ffffff",
                "primary-fixed": "#dae2ff",
                "surface-tint": "#0c56d0",
                "inverse-on-surface": "#eff1f3",
                "tertiary-container": "#a33500",
                "tertiary-fixed": "#ffdbcf",
                "primary": "#003d9b",
                "on-primary": "#ffffff",
                "on-secondary-fixed": "#002115",
                "surface": "#f7f9fb",
                "on-secondary-fixed-variant": "#005139",
                "outline-variant": "#c3c6d6",
                "surface-dim": "#d8dadc"
            },
            borderRadius: {
                "DEFAULT": "0.25rem",
                "lg": "0.5rem",
                "xl": "0.75rem",
                "xxl": "1.5rem",
                "full": "9999px"
            },
            fontFamily: {
                "headline": ["Manrope"],
                "display": ["Manrope"],
                "body": ["Inter"],
                "label": ["Inter"]
            }
        }
    }
};

document.addEventListener('DOMContentLoaded', () => {
    // Redireciona para a página principal (Flutter app)
    const handleRedirect = (e) => {
        if (e) e.preventDefault();
        window.location.href = 'patient.html';
    };

    // Aplica o evento a todos os botões e links
    const buttons = document.querySelectorAll('button');
    buttons.forEach(button => {
        // Ignora o botão de ver a senha para não redirecionar
        const isVisibilityButton = button.querySelector('[data-icon="visibility"]');
        if (!isVisibilityButton) {
            button.addEventListener('click', handleRedirect);
        } else {
            // Lógica do botão de visibilidade da senha
            button.addEventListener('click', (e) => {
                e.preventDefault();
                const input = document.getElementById('password');
                const icon = button.querySelector('span');
                if (input.type === 'password') {
                    input.type = 'text';
                    icon.textContent = 'visibility_off';
                } else {
                    input.type = 'password';
                    icon.textContent = 'visibility';
                }
            });
        }
    });

    const links = document.querySelectorAll('a');
    links.forEach(link => {
        link.addEventListener('click', handleRedirect);
    });
});
