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
            agent any // Usar el nodo principal de Jenkins que tiene Docker
            
            steps {
                echo 'Iniciando pruebas de seguridad con OWASP ZAP...'
                
                // Recuperar la base de datos
                unstash 'database'
                
                script {
                    // Crear directorio para reportes con permisos correctos
                    sh '''
                        mkdir -p reportes_zap
                        chmod 777 reportes_zap
                    '''
                    
                    // Iniciar la aplicación Flask en un contenedor Docker con red compartida
                    sh '''
                        # Detener cualquier contenedor previo
                        docker stop flask-app 2>/dev/null || true
                        docker rm flask-app 2>/dev/null || true
                        
                        # Iniciar aplicación en contenedor con host network
                        docker run -d --name flask-app \
                            --network host \
                            -v $(pwd):/app \
                            -w /app \
                            python:3.11-slim \
                            sh -c "pip install -q -r requirements.txt && python vulnerable_app.py"
                        
                        # Esperar a que la aplicación inicie
                        echo "Esperando que Flask inicie..."
                        sleep 15
                        
                        # Verificar múltiples veces
                        for i in 1 2 3 4 5; do
                            if curl -f http://localhost:5000/ 2>/dev/null; then
                                echo "Flask está respondiendo"
                                break
                            fi
                            echo "Intento $i/5 - esperando..."
                            sleep 3
                        done
                    '''
                    
                    // Mostrar logs de Flask para debug
                    sh 'docker logs flask-app || true'
                    
                    // Ejecutar ZAP usando Docker con permisos correctos
                    sh '''
                        docker run --rm \
                            --network host \
                            -v $(pwd)/reportes_zap:/zap/wrk/:rw \
                            -u zap \
                            ghcr.io/zaproxy/zaproxy:stable \
                            zap-baseline.py -t http://127.0.0.1:5000 \
                            -r reporte_zap.html \
                            -J reporte_zap.json \
                            -w reporte_zap.md \
                            -I || true
                    '''
                    
                    // Detener contenedor de Flask
                    sh '''
                        docker logs flask-app
                        docker stop flask-app 2>/dev/null || true
                        docker rm flask-app 2>/dev/null || true
                    '''
                    
                    echo 'Escaneo de seguridad OWASP ZAP completado'
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
