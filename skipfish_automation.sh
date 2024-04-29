#!/bin/bash

# Verificación de los parámetros de entrada
if [ $# -lt 1 ]; then
    echo "Uso: $0 archivo_objetivos"
    exit 1
fi

# Archivo que contiene la lista de objetivos
archivo_objetivos="$1"

# Verificar si el archivo de objetivos existe
if [ ! -f "$archivo_objetivos" ]; then
    echo "El archivo $archivo_objetivos no existe."
    exit 1
fi

# Mostrar el contenido del archivo de objetivos para propósitos de depuración
echo "Contenido del archivo de objetivos:"
cat "$archivo_objetivos"

# Función para procesar una línea de objetivo
procesar_objetivo() {
    local objetivo="$1"
    # Eliminar espacios en blanco alrededor de la línea
    objetivo=$(echo "$objetivo" | sed 's/^[ \t]*//;s/[ \t]*$//')
    # Si la línea está vacía, retornar
    [ -z "$objetivo" ] && return
    # Eliminar "http://" o "https://" del inicio del objetivo
    linea_sin_http=$(echo "$objetivo" | sed -e 's,^\(http://\|https://\),,')
    # Ejecutar Skipfish con el objetivo actual
    skipfish -o "$linea_sin_http"_skipfish "$objetivo"
}

# Número máximo de procesos en ejecución simultánea
max_procesos=1000
# Contador para rastrear el número de procesos activos
contador_procesos=0

# Iterar sobre cada objetivo en el archivo
while IFS= read -r objetivo; do
    # Si se alcanza el número máximo de procesos activos, esperar a que algunos terminen
    while [ $contador_procesos -ge $max_procesos ]; do
        sleep 1
        contador_procesos=$(jobs -p | wc -l)
    done
    # Procesar el objetivo en un proceso separado
    procesar_objetivo "$objetivo" &
    # Incrementar el contador de procesos activos
    contador_procesos=$((contador_procesos + 1))
done < "$archivo_objetivos"

# Esperar a que todos los procesos en segundo plano terminen
wait

# Salir del script
exit 0
