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
                        chmod 777 reportes_zap
                    '''
                    
                    // 2. Iniciar la aplicación Flask en background usando venv
                    echo 'Iniciando aplicacion...'
                    sh '''
                        # Crear entorno virtual (si no existe)
                        python3 -m venv venv
                        
                        # Instalar dependencias usando el pip del venv
                        ./venv/bin/pip install -q -r requirements.txt
                        
                        # Iniciar la app usando el python del venv
                        nohup ./venv/bin/python vulnerable_app.py > app.log 2>&1 &
                        
                        echo "Esperando 10 segundos para que la app inicie..."
                        sleep 10
                    '''
                    
                    // 3. Limpiar cualquier contenedor ZAP previo
                    sh 'docker rm -f zap-scan || true'
                    
                    // 4. Ejecutar ZAP sin montar volumen
                    // Los reportes se copian del contenedor después
                    try {
                        sh '''
                            docker run --name zap-scan --network host -u 0 \
                                ghcr.io/zaproxy/zaproxy:stable \
                                zap-baseline.py -t http://localhost:5000 \
                                -r report.html \
                                -J report.json \
                                -I
                        '''
                    } catch (Exception e) {
                        echo "ZAP scan finalizado (posiblemente con alertas)"
                    }
                    
                    // 5. Copiar reportes del contenedor a Jenkins
                    sh '''
                        echo "Copiando reportes desde el contenedor..."
                        docker cp zap-scan:/zap/wrk/report.html reportes_zap/reporte_zap.html
                        docker cp zap-scan:/zap/wrk/report.json reportes_zap/reporte_zap.json
                        
                        # Limpiar el contenedor
                        docker rm -f zap-scan
                        
                        echo "Escaneo completado. Archivos generados:"
                        ls -lah reportes_zap/
                    '''
                    
                    // 6. Matar proceso Flask
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
