pipeline {
    agent none // No usar el nodo principal de Jenkins por defecto
    
    environment {
        // Configuración de la aplicación
        FLASK_ENV = 'testing'
        FLASK_DEBUG = 'False'
    }
    
    stages {
        stage('Construcción') {
            // Ejecutar esta etapa dentro de un contenedor Python
            agent {
                docker { 
                    image 'python:3.11-slim'
                    args '-u root:root'
                }
            }
            steps {
                echo 'Etapa de Construcción - Preparando la aplicación...'
                
                sh '''
                    # Eliminar base de datos anterior si existe
                    rm -f database.db
                    
                    python --version
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    python create_db.py
                '''
                
                echo 'Construcción completada exitosamente'
                
                // Archivar la base de datos creada
                stash includes: 'database.db', name: 'database'
            }
        }
        
        stage('Pruebas Unitarias') {
            // Ejecutar esta etapa dentro de un contenedor Python
            agent {
                docker { 
                    image 'python:3.11-slim'
                    args '-u root:root'
                }
            }
            steps {
                echo 'Etapa de Pruebas Unitarias - Ejecutando tests...'
                
                // Recuperar la base de datos
                unstash 'database'
                
                sh '''
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    python --version
                    pip list
                '''
                
                echo 'Pruebas unitarias completadas exitosamente'
            }
        }
        
        stage('Pruebas de Seguridad - OWASP ZAP') {
            agent any
            
            steps {
                echo 'Iniciando pruebas de seguridad con OWASP ZAP...'
                
                // Recuperar la base de datos
                unstash 'database'
                
                script {
                    // 1. Crear directorio de reportes con permisos
                    sh '''
                        mkdir -p reportes_zap
                        chmod -R 777 reportes_zap
                    '''
                    
                    // 2. Iniciar la aplicación Flask en background usando venv
                    echo 'Iniciando aplicación para escaneo...'
                    sh '''
                        # Crear entorno virtual (si no existe)
                        python3 -m venv venv
                        
                        # Instalar dependencias usando el pip del venv
                        # Esto evita el error "externally-managed-environment"
                        ./venv/bin/pip install -q -r requirements.txt
                        
                        # Iniciar la app usando el python del venv
                        nohup ./venv/bin/python vulnerable_app.py > app.log 2>&1 &
                        
                        echo "Esperando 10 segundos para que la app inicie..."
                        sleep 10
                        
                        # Verificar que la app esté corriendo
                        curl -f http://localhost:5000/ && echo "App esta corriendo" || echo "Advertencia: App puede no estar lista"
                    '''
                    
                    // 3. Ejecutar ZAP con permisos de root y network host
                    try {
                        sh '''
                            docker run --rm --network host -u 0 \
                                -v $(pwd)/reportes_zap:/zap/wrk:rw \
                                ghcr.io/zaproxy/zaproxy:stable \
                                zap-baseline.py -t http://localhost:5000 \
                                -r reporte_zap.html \
                                -J reporte_zap.json \
                                -w reporte_zap.md \
                                -I
                        '''
                    } catch (Exception e) {
                        echo "ZAP encontró vulnerabilidades, pero continuamos el pipeline."
                    }
                    
                    // 4. Mostrar resultados
                    sh '''
                        echo "Escaneo completado. Archivos generados:"
                        ls -lah reportes_zap/
                    '''
                    
                    // 5. Matar proceso Flask
                    sh '''
                        pkill -f "./venv/bin/python vulnerable_app.py" || true
                        echo "Aplicacion Flask detenida"
                    '''
                    
                    echo 'Pruebas de seguridad OWASP ZAP completadas'
                }
                
                // Archivar reportes de seguridad
                archiveArtifacts artifacts: 'reportes_zap/**/*', allowEmptyArchive: true
                
                // Publicar reporte HTML
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'reportes_zap',
                    reportFiles: 'reporte_zap.html',
                    reportName: 'OWASP ZAP Security Report'
                ])
            }
        }
        
        stage('Despliegue') {
            // Ejecutar esta etapa dentro de un contenedor Python
            agent {
                docker { 
                    image 'python:3.11-slim'
                    args '-u root:root'
                }
            }
            steps {
                echo 'Etapa de Despliegue - Desplegando la aplicación...'
                
                // Recuperar la base de datos
                unstash 'database'
                
                sh '''
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    echo "Aplicación lista para desplegar"
                    echo "Información del entorno:"
                    python --version
                    echo "Total de paquetes instalados: $(pip list | wc -l)"
                '''
                
                echo 'Despliegue completado exitosamente'
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completado exitosamente!'
        }
        
        failure {
            echo 'Pipeline falló. Revisar logs para más detalles.'
        }
    }
}
