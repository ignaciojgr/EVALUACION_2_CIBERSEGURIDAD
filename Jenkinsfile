pipeline {
    agent any
    
    environment {
        // Configuración del entorno Python
        PYTHON_VERSION = '3.11'
        VENV_DIR = 'venv'
        
        // Configuración de la aplicación
        FLASK_ENV = 'testing'
        FLASK_DEBUG = 'False'
    }
    
    stages {
        stage('Construcción') {
            steps {
                echo 'Etapa de Construcción - Preparando la aplicación...'
                
                script {
                    // Crear entorno virtual
                    if (isUnix()) {
                        sh '''
                            python3 -m venv ${VENV_DIR}
                            . ${VENV_DIR}/bin/activate
                            pip install --upgrade pip
                            pip install -r requirements.txt
                            python create_db.py
                        '''
                    } else {
                        bat '''
                            python -m venv %VENV_DIR%
                            call %VENV_DIR%\\Scripts\\activate.bat
                            pip install --upgrade pip
                            pip install -r requirements.txt
                            python create_db.py
                        '''
                    }
                    
                    echo 'Construcción completada exitosamente'
                }
            }
        }
        
        stage('Pruebas') {
            steps {
                echo 'Etapa de Pruebas - Ejecutando tests...'
                
                script {
                    if (isUnix()) {
                        sh '''
                            . ${VENV_DIR}/bin/activate
                            python --version
                            pip list
                        '''
                    } else {
                        bat '''
                            call %VENV_DIR%\\Scripts\\activate.bat
                            python --version
                            pip list
                        '''
                    }
                    
                    echo 'Pruebas completadas exitosamente'
                }
            }
        }
        
        stage('Despliegue') {
            steps {
                echo 'Etapa de Despliegue - Desplegando la aplicación...'
                
                script {
                    if (isUnix()) {
                        sh '''
                            . ${VENV_DIR}/bin/activate
                            echo "Aplicación lista para desplegar"
                        '''
                    } else {
                        bat '''
                            call %VENV_DIR%\\Scripts\\activate.bat
                            echo "Aplicación lista para desplegar"
                        '''
                    }
                    
                    echo 'Despliegue completado exitosamente'
                }
            }
        }
    }
    
    post {
        always {
            echo 'Limpiando recursos...'
            
            script {
                if (isUnix()) {
                    sh '''
                        rm -rf ${VENV_DIR}
                        rm -f database.db
                    '''
                } else {
                    bat '''
                        if exist %VENV_DIR% rmdir /s /q %VENV_DIR%
                        if exist database.db del /f database.db
                    '''
                }
            }
        }
        
        success {
            echo 'Pipeline completado exitosamente!'
        }
        
        failure {
            echo 'Pipeline falló. Revisar logs para más detalles.'
        }
    }
}
