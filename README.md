# 📡 IOLANDA - Ionospheric Observation, Logging, Analysis and Data Application

O **IOLANDA** é um sistema integrado para gerenciamento, processamento e análise de dados ionosféricos, voltado para laboratórios de física espacial e pesquisadores da área. Ele unifica tarefas que atualmente dependem de múltiplas ferramentas (UDIDA, Python, MATLAB), oferecendo um fluxo de trabalho centralizado e eficiente. O sistema é compatível com dados de ionossondas do tipo **CADI**.

---

## 🎥 Vídeo de Funcionamento
Assista ao vídeo demonstrativo do sistema no YouTube:  
<p align="center">
  <a href="https://youtu.be/MzIX_Qi7GUo">
    <img src="https://img.youtube.com/vi/MzIX_Qi7GUo/0.jpg" alt="IOLANDA Demo" width="480"/>
  </a>
</p>

---

## 🎯 Objetivos do Projeto

- Automatizar o fluxo desde a importação de dados até a análise final.  
- Garantir consistência e confiabilidade das séries temporais de parâmetros ionosféricos.  
- Facilitar a visualização e comparação de dados entre usuários, observatórios e períodos distintos.  

---

<p align="center">
  <img src="Projeto IOLANDA/logos/logo-readme.png" alt="IOLANDA Logo" width="120"/>
</p>

**Figura:** Logo do sistema IOLANDA, representando sua função de integração e centralização de dados ionosféricos de forma intuitiva e confiável.

---

## 🛠 Funcionalidades

### 1. Gerenciamento de Usuários e Observatórios
- Login seguro por e-mail e senha.
- Cadastro e gerenciamento de observatórios (localização, identificação).
- Banco de dados centralizado para armazenar informações de usuários, observatórios e séries temporais.

### 2. Leitura, Conversão e Pré-Processamento de Dados
- Importação de arquivos `.SJC` ou similares.
- Conversão automática para `.txt` padronizado (yyyy.MM.dd (DDD) HH:mm:ss foF2 h`F hmF2).
- Preenchimento de lacunas com `NaN` para manter consistência.
- Concatenação de múltiplos arquivos em um único arquivo `.txt` para análise e plotagem.

### 3. Armazenamento de Dados Reduzidos
- Salvamento dos valores processados em banco de dados interno.
- Estrutura otimizada para consultas rápidas e filtragem por parâmetros, datas ou observatórios.

### 4. Visualização e Comparação Gráfica
- Plotagem de parâmetros ionosféricos: `h′F`, `hmF2`, `foF2` e suas variações `Δh′F`, `ΔhmF2`, `ΔfoF2`.
- Comparação de gráficos entre diferentes usuários ou observatórios.
- Seleção personalizável do período de análise.

### 5. Integração com Dados Externos (OMNIWeb)
- Importação automática de dados de campos magnéticos e vento solar com resolução de 5 minutos.
- Sincronização entre dados CADI e OMNIWeb.

### 6. Análise Estatística e Comparativa
- Cálculo de médias, desvios padrão e identificação de anomalias.
- Comparação entre observatórios e períodos distintos.
- Definição de dias calmos para cálculo da linha de base (mínimo 5, máximo 10 dias).

---

## 🛠 Tecnologias Utilizadas

- **Python**: Leitura, conversão e pré-processamento de dados, integração com banco de dados e interface gráfica.  
- **MATLAB**: Cálculos de parâmetros ionosféricos e geração de gráficos.  
- **Banco de Dados Relacional**: Armazenamento seguro de dados de usuários, observatórios e séries temporais.  
- **Engenharia de Software**: Modularização, controle de versão, manutenção, escalabilidade e reuso.  
- **Interface Gráfica**: Design ergonômico e amigável para usuários não técnicos.  

---

## 📂 Estrutura do Projeto

```bash
projeto-iolanda/
├── iolanda_api.py
├── requirements.txt
├── Arquivos do IOLANDA (versão 2.9).txt
├── Caminho para o arquivo executável.txt
├── Dados - Demonstração/
├── projeto-iolanda (versão 1.0)/
├── Dados (reduzidos do UDIDA)/
├── logos/
└── README.md
```

## 📌 Observações

 - O sistema garante consistência de séries temporais mesmo com dados ausentes.

 - Permite análise estatística avançada e comparativa entre múltiplos observatórios.

 - Interface amigável voltada a usuários de laboratórios de física espacial.

## 🤝 Agradecimentos

Projeto desenvolvido no contexto acadêmico com orientação de professores da área de Física Espacial e Engenharia da Computação.

## 📜 Licença

Este repositório está licenciado sob MIT License. Consulte o arquivo LICENSE para mais informações.
