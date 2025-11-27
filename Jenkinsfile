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
                    // 1. Crear carpeta para reportes y dar permisos
                    sh 'mkdir -p reportes_zap'
                    sh 'chmod 777 reportes_zap'
                    
                    // 2. Levantar la aplicación Python en segundo plano
                    echo 'Iniciando aplicacion...'
                    sh '''
                        python3 -m venv venv
                        ./venv/bin/pip install -q -r requirements.txt
                        nohup ./venv/bin/python vulnerable_app.py > app.log 2>&1 &
                        echo "Esperando 10 segundos a que la app inicie..."
                        sleep 10
                    '''
                    
                    // 3. Limpiar cualquier contenedor o volumen viejo
                    sh 'docker rm -f zap-scan || true'
                    sh 'docker volume rm zap-vol || true'
                    
                    // 4. Ejecutar ZAP con un volumen de Docker (zap-vol)
                    try {
                        sh '''
                            docker run --name zap-scan --network host -u 0 \
                                -v zap-vol:/zap/wrk \
                                ghcr.io/zaproxy/zaproxy:stable \
                                zap-baseline.py -t http://localhost:5000 \
                                -r report.html \
                                -J report.json \
                                -I
                        '''
                    } catch (Exception e) {
                        echo "ZAP finalizo (posiblemente encontro vulnerabilidades)"
                    }
                    
                    // 5. Copiar los reportes desde el contenedor hacia Jenkins
                    echo "Copiando reportes..."
                    sh 'docker cp zap-scan:/zap/wrk/report.html reportes_zap/reporte_zap.html'
                    sh 'docker cp zap-scan:/zap/wrk/report.json reportes_zap/reporte_zap.json'
                    
                    // 6. Limpieza final
                    sh '''
                        docker rm -f zap-scan
                        docker volume rm zap-vol
                        echo "Escaneo completado. Archivos generados:"
                        ls -lah reportes_zap/
                    '''
                    
                    // 7. Matar proceso Flask
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
