# defensa-ia

Laboratorio de **defensa de sistemas de IA asistida por IA** para el curso *Hacking con IA*.
Cada alumno blinda 10 chatbots vulnerables con cuatro capas (system prompt, reglas de entrada,
juez IA y reglas de salida), ayudado por un **copiloto IA**. Una batería de ataques visibles y
ocultos decide si el nivel está superado. Todo corre en local con Docker y Ollama: sin API keys
y sin coste.

## Requisitos

- Kali Linux (o cualquier Linux con Docker)
- 8 GB de RAM (16 GB recomendados) y 10 GB libres de disco
- Internet solo la primera vez (para descargar las imágenes y el modelo)

## Instalación en Kali (un comando)

```bash
git clone https://github.com/codeccs/lab-defensa-ia.git 
cd defensa-ia
bash instalar.sh
```

El script instala Docker si falta, arranca los contenedores, espera a que se descargue el modelo
(`qwen2.5:3b`, ~2 GB, solo la primera vez) y abre **http://localhost:8000**. Escribe tu nombre y
empieza por el nivel 1.

<details><summary>Instalación manual (sin el script)</summary>

```bash
sudo apt update && sudo apt install -y docker.io docker-compose git
sudo systemctl enable --now docker
sudo usermod -aG docker $USER && newgrp docker
cd lab-defensa-ia
docker compose up -d --build        # si da "unknown command", usa: docker-compose up -d --build
docker compose logs -f modelo       # espera a que termine la descarga; Ctrl+C
```
</details>

## Cómo se juega

1. **Lee el escenario** y los ataques conocidos. Además hay ataques **ocultos** que no ves.
2. **Escribe tus defensas** con las herramientas que permita el nivel.
3. **Pide ayuda al copiloto IA.** Conoce el nivel, tus defensas y los fallos de tu última batería. Sus
   propuestas se aplican con un botón, pero revísalas: también se equivoca.
4. **Prueba** en el chat de prueba y lanza la **batería**. Se supera con 0 fugas y como mucho 1 pregunta
   normal mal atendida, porque un bot que se niega a todo no sirve.

## Niveles

| # | Nivel | Riesgo OWASP | Herramientas | Puntos |
|---|-------|--------------|--------------|--------|
| 1 | La bóveda | LLM07, LLM02 | prompt | 100 |
| 2 | Políglota (codificaciones) | LLM02 | prompt, salida | 100 |
| 3 | Reglas confidenciales | LLM07 | prompt, salida | 150 |
| 4 | Datos de pacientes | LLM02 | prompt, salida, entrada | 150 |
| 5 | El documento envenenado | LLM01 indirecta | prompt, salida, entrada | 200 |
| 6 | Juego de rol (jailbreak) | LLM01 | prompt, salida, entrada | 200 |
| 7 | El botón de transferir | LLM06 | todas | 250 |
| 8 | Salida insegura (XSS) | LLM05 | prompt, salida, entrada | 250 |
| 9 | Engaña al juez (prompt bloqueado) | Guardrail LLM | entrada, juez | 300 |
| 10 | Jefe final | Todas | todas | 400 |

## Uso en el aula

- **Cada alumno en su Kali (recomendado):** cada uno ejecuta su propio `docker compose up`. Así las baterías
  van rápido porque nadie comparte el modelo.
- **Un servidor para toda la clase:** el instructor lo levanta y los alumnos entran desde el navegador en
  `http://<IP-del-servidor>:8000`. Sin GPU, Ollama atiende unas 2 peticiones a la vez, y una batería
  (9-12 pruebas) tarda 1-3 minutos. Con más de 5-6 alumnos usa GPU (descomenta el bloque `deploy`
  en `docker-compose.yml`) y sube `OLLAMA_NUM_PARALLEL` y `LLM_PARALELO`.
- El **marcador** (botón arriba a la derecha) muestra puntos y niveles blindados de cada alumno.

## Comandos útiles

| Acción | Comando |
|--------|---------|
| Parar / arrancar | `docker compose stop` / `docker compose start` |
| Ver logs | `docker compose logs -f lab` |
| Cambiar de modelo | `LLM_MODELO=qwen2.5:7b docker compose up -d` (el servicio `modelo` lo descarga) |
| Cambiar de puerto | `LAB_PUERTO=8080 docker compose up -d` |
| Borrar alumnos y puntuaciones | `docker compose down && docker volume rm lab-defensa-ia_datos && docker compose up -d` |

**Elegir modelo.** `qwen2.5:3b` es el término medio. Con `qwen2.5:1.5b` todo va más rápido, pero el bot es
más fácil de engañar y el juez y el copiloto fallan más. Con `qwen2.5:7b` (16 GB de RAM) el bot obedece
mejor el prompt defensivo y el copiloto da mejores consejos. Cambiar de modelo cambia la dificultad.

## Problemas frecuentes

| Síntoma | Solución |
|---------|----------|
| La web no carga | `docker compose ps`: `lab` solo arranca cuando `modelo` termina de descargar |
| «No se pudo contactar con el modelo» | `docker compose logs ollama`; comprueba que hay memoria libre |
| La batería tarda mucho | Normal en CPU; usa un modelo más pequeño o GPU |
| «Ese nombre ya existe» | El progreso va ligado al navegador; usa el mismo navegador o elige otro nombre |

## Notas para el instructor

Cada nivel enseña una idea concreta, y conviene comentarla al cerrar:

- **1-3:** el prompt defensivo ayuda, pero no basta contra codificaciones (base64, al revés) ni traducciones.
  Las reglas de salida sobre el *formato* del secreto (`ACERO-TIGRE-\d+`) son la red de seguridad.
- **4:** mínimo privilegio sobre los datos. El bot solo debe hablar de la paciente identificada.
- **5:** separar datos de instrucciones. Los documentos son datos; también conviene filtrar enlaces en la salida.
- **6:** los jailbreaks de rol se paran mejor con reglas sobre *qué* nunca se entrega que con una lista de trucos.
- **7:** la lección clave. Una regla de salida que solo permite `ACCION: transferir(ES76-0001, ...)` es
  determinista; ningún prompt lo garantiza.
- **8:** sanitizar la salida (scripts, `on*=`, `javascript:`) antes de publicar HTML generado por IA.
- **9:** el juez también es un LLM y se puede engañar. Hay que delimitar el mensaje, decirle que es un dato y
  vigilar los falsos positivos.
- **10:** defensa en profundidad. Ninguna capa sola aguanta todos los ataques.

**Estado de la verificación.** Probado de punta a punta con un Ollama *simulado*: registro, guardado, las
cuatro capas, detección de fugas (literal, separada por espacios, al revés y base64), batería, copiloto,
interfaz y marcador. No se ha podido probar con un modelo real: haz un ensayo completo con el modelo elegido
antes de la clase. Los modelos pequeños son impredecibles, y quizá tengas que ajustar ataques o preguntas
en `niveles.py`; después, `docker compose up -d --build`.
