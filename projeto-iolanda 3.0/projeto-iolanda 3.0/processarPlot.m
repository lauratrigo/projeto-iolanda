clear all;        % Remove todas as vari?veis do workspace, limpando a mem?ria
close all;        % Fecha todas as janelas de figuras abertas
clc;              % Limpa o texto do console (Command Window)

% BUSCA INTELIGENTE DE ESTA??O E DETEC??O AUTOM?TICA DE REDUTORES

% 1?? Usu?rio digita o nome ou parte da esta??o
prompt = {'Digite a sigla da estação (arg, jat ou sjc):'};
% Cria o texto da caixa de di?logo que ser? exibida na tela

titulo = 'Seleção de Estado';  % Define o t?tulo da janela de entrada
definput = {'arg'};             % Define o texto padr?o do campo (valor inicial)

% Abre uma janela para o usu?rio digitar o nome (ou parte) da esta??o
resposta = inputdlg(prompt, titulo, [1 50], definput);

if isempty(resposta)
    error('Nenhuma estação digitada.');  % Caso o usu?rio clique em ?Cancelar?, encerra o programa
end


% Converte o texto digitado para letras min?sculas e remove espa?os extras
palavraChave = lower(strtrim(resposta{1}));

% Fecha todas as msgbox abertas antes de abrir uma nova
msgboxHandles = findall(0, 'Type', 'figure');  % Encontra todas as janelas do tipo 'figure'
for i = 1:length(msgboxHandles)
    if strcmp(get(msgboxHandles(i), 'Tag'), 'TMW_MSGBOX')  % Verifica se é uma msgbox
        delete(msgboxHandles(i));  % Fecha a msgbox
    end
end

% Agora você pode abrir a nova msgbox normalmente
msgbox('Selecione a pasta principal que contém os arquivos (.txt).', 'Seleção de pasta');

pastaBase = uigetdir(pwd, 'Selecione a pasta principal');
% Abre um seletor de diret?rios para escolher a pasta base, iniciando no diret?rio atual (pwd)

if pastaBase == 0
    error('Nenhuma pasta selecionada.');  % Interrompe se o usu?rio cancelar
end

% 3?? Busca todos os arquivos .txt na pasta e subpastas
arquivos = dir(fullfile(pastaBase, '**', '*.txt'));
% Usa a fun??o dir com '**' para fazer busca recursiva (em todas as subpastas) por arquivos .txt

todosArquivos = fullfile({arquivos.folder}, {arquivos.name});
% Cria uma c?lula com o caminho completo de cada arquivo encontrado


% 4?? Filtra arquivos que cont?m o nome da esta??o (independente de mai?sculas/min?sculas)
mask = contains(lower(todosArquivos), palavraChave);
% Cria uma m?scara booleana (TRUE/FALSE) indicando se o nome da esta??o aparece em cada arquivo

arquivosEstacao = todosArquivos(mask);
% Mant?m apenas os arquivos que cont?m o nome da esta??o

if isempty(arquivosEstacao)
    % Caso n?o encontre nenhum arquivo correspondente ? esta??o digitada
    error(['Nenhum arquivo encontrado contendo "' palavraChave '" em ' pastaBase]);
end

% Exibe no console a lista de arquivos encontrados
disp('Arquivos encontrados nesta esta??o:');
disp(strjoin(arquivosEstacao, newline));  % Mostra os nomes um por linha no console

% 5?? Detecta automaticamente os redutores (nomes diferentes nos arquivos)

redutores = strings(0);  % Cria um vetor vazio para armazenar os nomes de redutores detectados

for i = 1:numel(arquivosEstacao)  % Percorre todos os arquivos da esta??o
    [~, nomeArquivo, ~] = fileparts(arquivosEstacao{i});
    % Extrai apenas o nome do arquivo (sem caminho nem extens?o)
    
    % Divide o nome do arquivo em partes, separando por '_' , '-' ou espa?o
    partes = split(nomeArquivo, {'_', '-', ' '});
    partes = string(partes(~cellfun('isempty', partes)));
    % Remove partes vazias (ex: duplo ?__? ou ?--?)
    
    % Procura fragmentos que contenham o nome da esta??o
    idx = contains(lower(partes), palavraChave);
    
    if any(idx)  % Se encontrar o nome da esta??o em alguma parte
        pos = find(idx);  % Pega as posi??es onde aparece
        for p = pos'
            % Busca o termo anterior e posterior ? esta??o (poss?veis redutores)
            if p > 1
                cand = partes(p-1);  % Parte anterior
                if strlength(cand) > 2 && ~contains(lower(cand), palavraChave)
                    redutores(end+1) = upper(cand);  % Adiciona o nome em letras mai?sculas
                end
            end
            if p < numel(partes)
                cand = partes(p+1);  % Parte seguinte
                if strlength(cand) > 2 && ~contains(lower(cand), palavraChave)
                    redutores(end+1) = upper(cand);
                end
            end
        end
    end
end

% Fecha todas as msgbox abertas antes de abrir uma nova
msgboxHandles = findall(0, 'Type', 'figure');  % Encontra todas as janelas do tipo 'figure'
for i = 1:length(msgboxHandles)
    if strcmp(get(msgboxHandles(i), 'Tag'), 'TMW_MSGBOX')  % Verifica se é uma msgbox
        delete(msgboxHandles(i));  % Fecha a msgbox
    end
end

% Agora você pode abrir a nova msgbox normalmente
msgbox('Selecione a pasta principal que contém os arquivos (.txt).', 'Seleção de pasta');

% Remove duplicatas e ordena em ordem alfab?tica
redutores = unique(redutores);

if isempty(redutores)
    msgbox('Nenhum nome de redutor detectado automaticamente.');  % Exibe aviso se nada for encontrado
else
    msgbox(sprintf('Redutores encontrados: %s', strjoin(redutores, ', ')), 'Redutores detectados');
end


% 6?? Usu?rio escolhe um ou mais redutores
[indiceEscolhido, ok] = listdlg( ...
    'PromptString', 'Selecione o(s) redutor(es):', ...   % Texto da janela
    'SelectionMode', 'multiple', ...                     % Permite selecionar mais de um
    'ListString', cellstr(redutores), ...                % Lista de op??es exibida
    'Name', 'Sele??o de redutores', ...                  % T?tulo da janela
    'ListSize', [400 300]);                              % Tamanho da janela (largura x altura)

if ~ok
    error('Nenhum redutor selecionado.');  % Se o usu?rio cancelar, encerra o programa
end


% 7?? Filtra apenas arquivos que tenham a esta??o e o redutor escolhido
selecionados = {};      % Inicializa vetor para os arquivos finais
arquivosRedutor = {};   % Vetor tempor?rio

for r = redutores(indiceEscolhido)'  % Para cada redutor selecionado pelo usu?rio
    nomeRedutor = lower(strtrim(r));  % Converte para min?sculo e remove espa?os
    maskR = contains(lower(arquivosEstacao), nomeRedutor);  % Filtra arquivos com o nome desse redutor
    arquivosR = arquivosEstacao(maskR);
    
    if isempty(arquivosR)
        continue;  % Se n?o encontrou nada, pula para o pr?ximo redutor
    end
    
    % Mostra janela para escolher quais arquivos desse redutor usar
    [idxArqs, okArqs] = listdlg( ...
        'PromptString', sprintf('Selecione os arquivos do redutor %s:', upper(nomeRedutor)), ...
        'SelectionMode', 'multiple', ...
        'ListString', arquivosR, ...
        'Name', sprintf('Arquivos de %s', upper(nomeRedutor)), ...
        'ListSize', [500 300]);  % Janela grande para facilitar visualiza??o
    
    if okArqs
        arquivosRedutor = [arquivosRedutor, arquivosR(idxArqs)];  % Adiciona os arquivos escolhidos
    end
end

selecionados = arquivosRedutor;  % Copia os arquivos finais para a vari?vel principal

if isempty(selecionados)
    error('Nenhum arquivo foi selecionado.');  % Se n?o houver sele??o, encerra
end

% Fecha todas as msgbox abertas antes de abrir uma nova
msgboxHandles = findall(0, 'Type', 'figure');  % Encontra todas as janelas do tipo 'figure'
for i = 1:length(msgboxHandles)
    if strcmp(get(msgboxHandles(i), 'Tag'), 'TMW_MSGBOX')  % Verifica se é uma msgbox
        delete(msgboxHandles(i));  % Fecha a msgbox
    end
end

% Agora você pode abrir a nova msgbox normalmente
msgbox('Selecione a pasta principal que contém os arquivos (.txt).', 'Seleção de pasta');


% 8?? Mostra mensagem final com os arquivos confirmados
msg = sprintf('Foram selecionados %d arquivo(s):\n', numel(selecionados));
msg = [msg, strjoin(selecionados, newline)];  % Lista os arquivos com quebra de linha
msgbox(msg, 'Arquivos selecionados');  % Exibe caixa de mensagem


% SELE??O DE M?S E INTERVALO DE DIAS
% L? o primeiro arquivo selecionado (os demais seguem o mesmo padr?o)
fileID = fopen(selecionados{1}, 'r');
dataTmp = textscan(fileID, '%s %s %s %f %f %f', ...
    'HeaderLines', 1, 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
fclose(fileID);

% Extrai a coluna de datas e converte para datetime
datetime_str = strcat(dataTmp{1}, {' '}, dataTmp{3});
tempoTotal = datetime(datetime_str, 'InputFormat', 'yyyy.MM.dd HH:mm:ss');

% Detecta automaticamente o ano dispon?vel nos dados
anoDetectado = mode(year(tempoTotal));

% Mostra o intervalo de datas dispon?veis
msgbox(sprintf('Ano detectado automaticamente: %d\nPeríodo disponível: %s até %s', ...
    anoDetectado, datestr(min(tempoTotal)), datestr(max(tempoTotal))), ...
    'Informação sobre os dados');

% Pergunta apenas o m?s e intervalo de dias desejado
prompt = {'Mês (1-12):', 'Dia inicial:', 'Dia final:'};
titulo = 'Seleção de período de análise';
definput = {num2str(month(min(tempoTotal))), '1', num2str(day(max(tempoTotal)))};
resposta = inputdlg(prompt, titulo, [1 40], definput);

if isempty(resposta)
    error('Nenhum período foi informado.');
end

mesSelecionado  = str2double(resposta{1});
diaInicial      = str2double(resposta{2});
diaFinal        = str2double(resposta{3});

if any(isnan([mesSelecionado diaInicial diaFinal]))
    error('Valores inválidos para o período.');
end
if diaFinal < diaInicial
    error('O dia final não pode ser menor que o inicial.');
end

% FILTRA AUTOMATICAMENTE OS DADOS DO PER?ODO SELECIONADO

dadosFiltrados = [];
for i = 1:numel(selecionados)
    fileID = fopen(selecionados{i}, 'r');
    dataTmp = textscan(fileID, '%s %s %s %f %f %f', ...
        'HeaderLines', 1, 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
    fclose(fileID);
    
    datetime_str = strcat(dataTmp{1}, {' '}, dataTmp{3});
    tempo = datetime(datetime_str, 'InputFormat', 'yyyy.MM.dd HH:mm:ss');
    
    % Filtra o m?s e intervalo de dias escolhido
    maskPeriodo = (month(tempo) == mesSelecionado) & ...
        (day(tempo) >= diaInicial) & (day(tempo) <= diaFinal);
    
    for j = 1:numel(dataTmp)
        dataTmp{j} = dataTmp{j}(maskPeriodo);
    end
    
    % Junta dados filtrados
    if isempty(dadosFiltrados)
        dadosFiltrados = dataTmp;
    else
        for j = 1:numel(dataTmp)
            dadosFiltrados{j} = [dadosFiltrados{j}; dataTmp{j}];
        end
    end
end

% Verifica se encontrou dados no intervalo
if isempty(dadosFiltrados{1})
    error('Nenhum dado encontrado no período selecionado.');
end

% Cria o vetor de tempo filtrado (para o gr?fico)
datetime_str = strcat(dadosFiltrados{1}, {' '}, dadosFiltrados{3});
tempoSelecionado = datetime(datetime_str, 'InputFormat', 'yyyy.MM.dd HH:mm:ss');
tempoSelecionado_num = datenum(tempoSelecionado);

disp(['Per?odo selecionado: ' datestr(min(tempoSelecionado)) ' at? ' datestr(max(tempoSelecionado))]);

% SELECIONA O ARQUIVO OMNI (DO MESMO PER?ODO)
msgbox('Selecione o arquivo OMNI que contém o mesmo mês dos dados ionosféricos.', ...
    'Seleção de OMNI');

[arquivoOmni, caminhoOmni] = uigetfile({'*.txt','Arquivos de texto (*.txt)'}, ...
    'Selecione o arquivo OMNI do mesmo período');
if isequal(arquivoOmni,0)
    error('Nenhum arquivo OMNI selecionado.');
end
filenameOmni = fullfile(caminhoOmni, arquivoOmni);

% CARREGA O ARQUIVO OMNI E FILTRA AUTOMATICAMENTE PELO PER?ODO

% Carrega todo o OMNI
%dataOmni = importdata(filenameOmni);
% Lê o OMNI tratado ignorando a primeira linha (cabeçalho)
dataOmni = readmatrix(filenameOmni, 'NumHeaderLines', 1);


% Constr?i vetor de tempo com base no n?mero de linhas (1 valor por minuto, hora, etc.)
% Ajuste aqui conforme a resolu??o temporal do seu arquivo OMNI
% Exemplo comum: dados de 1 em 1 minuto -> 1440 por dia
% Aqui, assumindo que o arquivo cobre todo o m?s escolhido:
diasNoMes = eomday(anoDetectado, mesSelecionado);
timeOmni = linspace(datenum(anoDetectado, mesSelecionado, 1), ...
    datenum(anoDetectado, mesSelecionado, diasNoMes+1), ...
    size(dataOmni,1));

% Cria m?scara para o intervalo de dias desejado
inicio = datenum(anoDetectado, mesSelecionado, diaInicial);
fim    = datenum(anoDetectado, mesSelecionado, diaFinal+1);
maskOmni = (timeOmni >= inicio) & (timeOmni < fim);

% Aplica o filtro aos dados
dataOmniFiltrado = dataOmni(maskOmni, :);
timeOmniFiltrado = timeOmni(maskOmni);

% ============================================================
% LER CABEÇALHO PARA DESCOBRIR OS NOMES DAS COLUNAS
% ============================================================
fid = fopen(filenameOmni);
headerLine = fgetl(fid);             % primeira linha = nomes das colunas
fclose(fid);

cols = strsplit(strtrim(headerLine));   % vira {'Year','Day','Hour','Min','BzG',...}
M = dataOmniFiltrado;

% ============================================================
% FUNÇÃO "INLINE" PARA ACHAR COLUNA PELO NOME
% ============================================================
findIdx = @(name) find(strcmpi(cols, name) | contains(lower(cols), lower(name)), 1);

% ============================================================
% BUSCAR APENAS AS COLUNAS NECESSÁRIAS
% ============================================================
iBz   = findIdx('Bz');     % funciona para BzG, BzE, BZ etc
iVsw  = findIdx('Spe');    % velocidade
iNsw  = findIdx('Den');    % densidade
iAE   = findIdx('AE');     % índice AE
iSymH = findIdx('SYMh');   % índice SYM-H

% ============================================================
% SE COLUNA EXISTIR ? EXTRAI
% SE NÃO ? PREENCHE COM NaN
% ============================================================
if isempty(iBz),   Bz   = NaN(size(M,1),1); else, Bz   = M(:,iBz);   end
if isempty(iVsw),  Vsw  = NaN(size(M,1),1); else, Vsw  = M(:,iVsw);  end
if isempty(iNsw),  Nsw  = NaN(size(M,1),1); else, Nsw  = M(:,iNsw);  end
if isempty(iAE),   AE   = NaN(size(M,1),1); else, AE   = M(:,iAE);   end
if isempty(iSymH), SymH = NaN(size(M,1),1); else, SymH = M(:,iSymH); end


% Mensagem informando o per?odo usado
msgbox(sprintf('OMNI selecionado automaticamente de %02d/%02d at? %02d/%02d/%d', ...
    diaInicial, mesSelecionado, diaFinal, mesSelecionado, anoDetectado), ...
    'Período OMNI aplicado');

% Cria vetor de tempo datetime para o gr?fico
timeOmniDatetime = datetime(timeOmniFiltrado, 'ConvertFrom', 'datenum');

% 9?? Mant?m compatibilidade com c?digo anterior (define filename1..3)
if numel(selecionados) >= 1, filename1 = selecionados{1}; end
if numel(selecionados) >= 2, filename2 = selecionados{2}; else, filename2 = filename1; end
if numel(selecionados) >= 3, filename3 = selecionados{3}; else, filename3 = filename2; end

% 4?? Selecionar MAT
msgbox('Agora selecione o arquivo mediasedesvios.mat', 'Sele??o do arquivo MAT');
% Mostra mensagem para selecionar o arquivo .mat com m?dias e desvios padr?o

[arquivoMat, caminhoMat] = uigetfile({'*.mat','Arquivos MAT (*.mat)'}, ...
    'Selecione o arquivo mediasedesvios.mat');
filenameMat = fullfile(caminhoMat, arquivoMat);
% Caminho completo do arquivo MAT selecionado

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Abre o primeiro arquivo de ionosfera para leitura
fileID = fopen(filename1, 'r');  % Abre o arquivo no modo leitura (read)
data1 = textscan(fileID, '%s %s %s %f %f %f', ...
    'HeaderLines', 1, ...           % Pula a primeira linha (cabe?alho)
    'Delimiter', ' ', ...           % Usa espa?o como delimitador
    'MultipleDelimsAsOne', true);   % Considera m?ltiplos espa?os como um s?
fclose(fileID);                     % Fecha o arquivo ap?s leitura

% L? o segundo arquivo (mesmo formato)
fileID = fopen(filename2, 'r');
data2 = textscan(fileID, '%s %s %s %f %f %f', 'HeaderLines', 1, ...
    'Delimiter', ' ', 'MultipleDelimsAsOne', true);
fclose(fileID);

% L? o terceiro arquivo
fileID = fopen(filename3, 'r');
data3 = textscan(fileID, '%s %s %s %f %f %f', 'HeaderLines', 1, ...
    'Delimiter', ' ', 'MultipleDelimsAsOne', true);
fclose(fileID);

% Extrai as colunas de data e hora do primeiro arquivo
date_str = data1{1};    % Primeira coluna: data (ex: "2017.08.01")
time_str = data1{3};    % Terceira coluna: hora (ex: "12:30:00")

% Mostra no console o tamanho (n?mero de linhas) de cada coluna lida
size(data1{6})
size(data2{6})
size(data3{6})

% Calcula a m?dia ponto a ponto entre os tr?s arquivos
% Se um valor for NaN em algum arquivo, o nanmean ignora e calcula a m?dia dos restantes
foF2 = nanmean([data1{4} data2{4} data3{4}], 2);  % Coluna 4 ? foF2 (MHz)
hF   = nanmean([data1{5} data2{5} data3{5}], 2);  % Coluna 5 ? h'F (km)
hmF2 = nanmean([data1{6} data2{6} data3{6}], 2);  % Coluna 6 ? hmF2 (km)

%%%%%%%%%AQUI
% === FILTRA OS DADOS IONOSF?RICOS PELO PER?ODO SELECIONADO (DIAS ESCOLHIDOS) ===
inicio_plot = datenum(anoDetectado, mesSelecionado, diaInicial);
fim_plot    = datenum(anoDetectado, mesSelecionado, diaFinal + 1);

% Combina data e hora do primeiro arquivo
datetime_str = strcat(date_str, {' '}, time_str);
time = datetime(datetime_str, 'InputFormat', 'yyyy.MM.dd HH:mm:ss');
tempo_num = datenum(time);

% Cria m?scara para manter apenas o intervalo selecionado
maskPeriodo = (tempo_num >= inicio_plot) & (tempo_num < fim_plot);

% Aplica a m?scara a todas as vari?veis ionosf?ricas
time = time(maskPeriodo);
foF2 = foF2(maskPeriodo);
hF   = hF(maskPeriodo);
hmF2 = hmF2(maskPeriodo);

% === AJUSTE CORRETO AP?S FILTRO DOS DIAS ===
% Atualiza o eixo de tempo para refletir apenas o per?odo selecionado
start_time = min(time);                      % In?cio real do per?odo escolhido
end_time   = max(time);                      % Fim real do per?odo escolhido
full_time  = time;                           % Mant?m apenas o vetor filtrado
full_time_numeric = datenum(full_time);      % Converte para n?mero serial (como Omni)

% Exibe o per?odo escolhido no console (opcional)
disp(['Intervalo selecionado: ', datestr(start_time), ' at? ', datestr(end_time)]);

% ====== EIXO X FIXO: MOSTRA OS PONTINHOS MESMO COM MENOS DIAS ======
X0 = datenum(anoDetectado, mesSelecionado, diaInicial);
X1 = datenum(anoDetectado, mesSelecionado, diaFinal + 1);

% Limites travados
XLIM_FIXO = [X0 X1];

% Ticks principais: 1 por dia
XT_MAJOR = X0:1:X1;

% Minor ticks fixos no meio de cada dia
if numel(XT_MAJOR) > 1
    XT_MINOR = XT_MAJOR(1:end-1) + 0.5;  % ponto entre os dias
else
    XT_MINOR = X0 + 0.5;  % se s? um dia, ainda mostra um pontinho
end

% R?tulos (formato mm/dd)
XT_LABELS = cellstr(datestr(XT_MAJOR, 'mm/dd'));

% Load data from the provided file
data = importdata(filenameOmni);                                  % L? o arquivo OMNI (texto) para a matriz 'data'



% Aqui usamos o OMNI já filtrado e lido corretamente
M = dataOmniFiltrado;

% Lê o cabeçalho para saber a posição real das colunas
fid = fopen(filenameOmni,'r');
headerLine = fgetl(fid);
fclose(fid);
cols = strsplit(strtrim(headerLine));

% Função auxiliar para localizar colunas por nome
findIdx = @(name) find(strcmpi(cols,name) | contains(lower(cols), lower(name)), 1);

% Localizar índices das variáveis desejadas
iBz   = findIdx('BzG');     % pode ser Bz, BzG, Bz GSM
iVsw  = findIdx('Spe');     % velocidade do vento solar
iNsw  = findIdx('Den');     % densidade
iAE   = findIdx('AE');      % índice AE
iSymH = findIdx('SYMh');    % índice Sym-H

disp("Encontrou SymH na coluna: " + iSymH);
if ~isempty(iSymH)
    disp("Nome real da coluna: " + cols{iSymH});
end
% Extrair com fallback para NaN
if isempty(iBz),   Bz   = NaN(size(M,1),1); else, Bz   = M(:,iBz); end
if isempty(iVsw),  Vsw  = NaN(size(M,1),1); else, Vsw  = M(:,iVsw); end
if isempty(iNsw),  Nsw  = NaN(size(M,1),1); else, Nsw  = M(:,iNsw); end
if isempty(iAE),   AE   = NaN(size(M,1),1); else, AE   = M(:,iAE); end
if isempty(iSymH), SymH = NaN(size(M,1),1); else, SymH = M(:,iSymH); end

% Time axis usando o vetor filtrado original
time2 = timeOmniFiltrado;



% Initialize arrays to store complete data
full_foF2  = NaN(size(full_time));
full_hF    = NaN(size(full_time));
full_hmF2  = NaN(size(full_time));

% Fill the complete data arrays
[~, ia, ib] = intersect(full_time, time);
full_foF2(ia) = foF2(ib);
full_hF(ia)   = hF(ib);
full_hmF2(ia) = hmF2(ib);

% Prote??o contra erro de ?ndice
if numel(full_foF2) >= 641
    full_foF2(641) = NaN;
    full_hF(641)   = NaN;
    full_hmF2(641) = NaN;
end


% Load the variables from the 'mediasedesvios.mat' file
load(filenameMat, 'mediahF', 'desviohF', 'mediaf0F2', 'desviof0F2', 'mediahmF2', 'desviohmF2');

grayColor = [0.7, 0.7, 0.7];

figure;
desviohmF2(isnan(desviohmF2)) = 0;
desviof0F2(isnan(desviof0F2)) = 0;
figure1 = figure(1);
% ===================== SUBPLOT 1: Sym-H =======================
subplot(7,1,1);
plot(time2, SymH, '-b', 'LineWidth', 2);
hold on; grid on;
% ====== CONFIGURA??O DO EIXO X (id?ntica ao subplot 2) ======
ax = gca;
ax.XAxis.LineWidth = 2;
ax.XTick = min(full_time_numeric):4*0.2498:max(full_time_numeric);
ax.XMinorTick = 'on';
ax.MinorGridAlpha = 0.5;
minor_ticks = min(full_time_numeric):0.2498:max(full_time_numeric);
ax.XAxis.MinorTickValues = minor_ticks;
xlim([min(full_time_numeric) max(full_time_numeric)]);
ax.TickDir = 'in';
ax.TickLength = [0.01 0.01];
ylabel('SymH (nT)');
set(gca,'XTickLabel',[]);  % Oculta r?tulos (s? no ?ltimo subplot)
% ====================== SUBPLOT 2: h'F =======================
subplot(7,1,2);
plot(full_time_numeric, full_hF, '-b');
ax = gca;
ax.XAxis.LineWidth = 2;
hold on; grid on;

% ====== MÉDIAS E DESVIOS ======
N = length(full_time_numeric);
[mediahF, desviohF] = stretch_mean_std(mediahF, desviohF, N);


% ====== PLOTAGEM ======
plot(full_time_numeric, mediahF, 'k-', 'LineWidth', 2);
fill_area_x = [full_time_numeric; flipud(full_time_numeric)];
fill_area_y = [mediahF + desviohF; flipud(mediahF - desviohF)];
fill(fill_area_x, fill_area_y, grayColor, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

% ====== CONFIGURA??O DO EIXO (id?ntica ao subplot 3) ======
ax.XTick = min(full_time_numeric):4*0.2498:max(full_time_numeric);
set(gca,'XTickLabel',[]);
ylabel("h'F (km)");
ax.XMinorTick = 'on';
ax.MinorGridAlpha = 0.5;
minor_ticks = min(full_time_numeric):0.2498:max(full_time_numeric);
ax.XAxis.MinorTickValues = minor_ticks;
xlim([min(full_time_numeric) max(full_time_numeric)]);

% ====================== SUBPLOT 3: hmF2 =======================
subplot(7,1,3);
plot(full_time_numeric, full_hmF2, '-b');
ax = gca;
ax.XAxis.LineWidth = 2;
ax.XTick = min(full_time_numeric):4*0.2498:max(full_time_numeric);
hold on; grid on;
N = length(full_time_numeric);
[mediahmF2, desviohmF2] = stretch_mean_std(mediahmF2, desviohmF2, N);

plot(full_time_numeric, mediahmF2, 'k-', 'LineWidth', 2);
fill_area_x = [full_time_numeric; flipud(full_time_numeric)];
fill_area_y = [mediahmF2 + desviohmF2; flipud(mediahmF2 - desviohmF2)];
fill(fill_area_x, fill_area_y, grayColor, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
ylabel('hmF2 (km)');
set(gca,'XTickLabel',[]);
grid on;
ax.XMinorTick = 'on';
ax.MinorGridAlpha = 0.5;
minor_ticks = min(full_time_numeric):0.2498:max(full_time_numeric);
ax.XAxis.MinorTickValues = minor_ticks;
xlim([min(full_time_numeric) max(full_time_numeric)]);

% ====================== SUBPLOT 4: foF2 =======================
subplot(7,1,4);
plot(full_time_numeric, full_foF2, '-b');
ax = gca;
ax.XAxis.LineWidth = 2;
ax.XTick = min(full_time_numeric):4*0.2498:max(full_time_numeric);
hold on; grid on;
N = length(full_time_numeric);
[mediaf0F2, desviof0F2] = stretch_mean_std(mediaf0F2, desviof0F2, N);
plot(full_time_numeric, mediaf0F2, 'k-', 'LineWidth', 2);
fill_area_x = [full_time_numeric; flipud(full_time_numeric)];
fill_area_y = [mediaf0F2 + desviof0F2; flipud(mediaf0F2 - desviof0F2)];
fill(fill_area_x, fill_area_y, grayColor, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
ylabel('foF2 (MHz)');
set(gca,'XTickLabel',[]);
grid on;
ax.XMinorTick = 'on';
ax.MinorGridAlpha = 0.5;
minor_ticks = min(full_time_numeric):0.2498:max(full_time_numeric);
ax.XAxis.MinorTickValues = minor_ticks;
xlim([min(full_time_numeric) max(full_time_numeric)]);

% ====================== RESTANTE DOS SUBPLOTS (5,6,7) =======================
% ====================== C?LCULO DAS M?DIAS NOTURNAS =======================
% ==== CÁLCULO DINÂMICO DOS ÍNDICES NOTURNOS ====
% Intervalo noturno: 21:00–24:00
t = full_time_numeric;
horaDecimal = mod(t - floor(t), 1) * 24;

% Máscara de 21h a 24h
maskNoite = (horaDecimal >= 21);

MAEnoitehF    = mean(abs(mediahF(maskNoite)));
MAEnoitef0F2  = mean(abs(mediaf0F2(maskNoite)));
MAEnoitehmF2  = mean(abs(mediahmF2(maskNoite)));

% ====================== SUBPLOT 5 ? ?h'F e ?ndice h'F =======================
subplot(7,1,5);
yyaxis left;
diff_hF = full_hF - mediahF;
diff_hF_plot = diff_hF;
nan_mask_hF = isnan(diff_hF_plot);
plot(full_time_numeric, diff_hF_plot, 'b.-');
ylim([-200,200]);
ax = gca;
ax.YColor = 'k';
hold on;
ylabel('\Delta h''F');
set(gca,'XTickLabel',[]);
ax.XAxis.LineWidth = 2;
ax.XTick = min(full_time_numeric):4*0.2498:max(full_time_numeric);
grid on;

yyaxis right;
diff_hF = full_hF - mediahF;
diff_std = desviohF;
for i = 1:length(diff_hF)
    if diff_hF(i,:) > diff_std(i,:)
        diff_hF(i,:) = diff_hF(i,:) - diff_std(i,:);
    elseif diff_hF(i,:) < -diff_std(i,:)
        diff_hF(i,:) = diff_hF(i,:) + diff_std(i,:);
    else
        diff_hF(i,:) = 0;
    end
end
diff_hF = (diff_hF / MAEnoitehF) * 100;
bar(full_time_numeric, diff_hF, 'FaceColor','g','FaceAlpha',0.5);
ylabel('Index h''F');
ylim([-50,50]);
grid on;
ax = gca;
ax.XMinorTick = 'on';
ax.MinorGridAlpha = 0.5;
ax.YColor = 'k';
minor_ticks = min(full_time_numeric):0.2498:max(full_time_numeric);
ax.XAxis.MinorTickValues = minor_ticks;
% ====================== SUBPLOT 6 ? ?hmF2 e ?ndice hmF2 =======================
subplot(7,1,6);
yyaxis left;
diff_hmF2 = full_hmF2 - mediahmF2;
diff_hmF2_plot = diff_hmF2;
nan_mask_hmF2 = isnan(diff_hmF2_plot);
plot(full_time_numeric, diff_hmF2_plot, 'b.-');
ylim([-200,200]);
hold on;
ylabel('\Delta hmF2');
set(gca,'XTickLabel',[]);
ax = gca;
ax.YColor = 'k';
ax.XAxis.LineWidth = 2;
ax.XTick = min(full_time_numeric):4*0.2498:max(full_time_numeric);
grid on;

yyaxis right;
diff_hmF2 = full_hmF2 - mediahmF2;
diff_std = desviohmF2;
for i = 1:length(diff_hmF2)
    if diff_hmF2(i,:) > diff_std(i,:)
        diff_hmF2(i,:) = diff_hmF2(i,:) - diff_std(i,:);
    elseif diff_hmF2(i,:) < -diff_std(i,:)
        diff_hmF2(i,:) = diff_hmF2(i,:) + diff_std(i,:);
    else
        diff_hmF2(i,:) = 0;
    end
end
diff_hmF2 = (diff_hmF2 / MAEnoitehmF2) * 100;
bar(full_time_numeric, diff_hmF2, 'FaceColor','g','FaceAlpha',0.5);
ylabel('Index hmF2');
ylim([-50,50]);
grid on;
ax = gca;
ax.XMinorTick = 'on';
ax.MinorGridAlpha = 0.5;
ax.YColor = 'k';
minor_ticks = min(full_time_numeric):0.2498:max(full_time_numeric);
ax.XAxis.MinorTickValues = minor_ticks;
ax.XAxis.LineWidth = 2;
ax.XTick = min(full_time_numeric):4*0.2498:max(full_time_numeric);
% ====================== SUBPLOT 7 ? ?foF2 e ?ndice foF2 =======================
subplot(7,1,7);
yyaxis left;
diff_f0F2 = full_foF2 - mediaf0F2;
plot(full_time_numeric, diff_f0F2, 'b.-');
ax.YColor = 'k';
ylim([-5,5]);
hold on;
ylabel('\Delta foF2');
xlabel('Time (Days)');
ax = gca;
ax.YColor = 'k';

yyaxis right;
diff_f0F2 = full_foF2 - mediaf0F2;
diff_std = desviof0F2;
for i = 1:length(diff_f0F2)
    if diff_f0F2(i,:) > diff_std(i,:)
        diff_f0F2(i,:) = diff_f0F2(i,:) - diff_std(i,:);
    elseif diff_f0F2(i,:) < -diff_std(i,:)
        diff_f0F2(i,:) = diff_f0F2(i,:) + diff_std(i,:);
    else
        diff_f0F2(i,:) = 0;
    end
end
diff_f0F2 = (diff_f0F2 / MAEnoitef0F2) * 100;
bar(full_time_numeric, diff_f0F2, 'FaceColor','g','FaceAlpha',0.5);
ylabel('Index foF2');
xlabel('Time (Days)');
ylim([-50,50]);
grid on;
ax = gca;
ax.XMinorTick = 'on';
ax.MinorGridAlpha = 0.5;
ax.YColor = 'k';
minor_ticks = min(full_time_numeric):0.2498:max(full_time_numeric);
ax.XAxis.MinorTickValues = minor_ticks;
ax.XAxis.LineWidth = 2;
ax.XTick = min(full_time_numeric):4*0.2498:max(full_time_numeric);
% ======= EIXO X FINAL AJUSTADO AO INTERVALO SELECIONADO =======
diasTotal = days(max(time) - min(time)) + 1;
if diasTotal < 2
    step = 0.25;  % 6h se for 1 dia
else
    step = 1;     % 1 dia se for mais de um
end
ax.XTick = min(full_time_numeric):step:max(full_time_numeric);
month_day = arrayfun(@(x) datestr(x, 'mm/dd'), ax.XTick, 'UniformOutput', false);
ax.XTickLabel = month_day;


% ======= ================================ =======%
% ======= ================================ =======%
% ============================================================
% === PLOTAGEM AUTOMÁTICA DE PARÂMETROS OMNI (COM CABEÇALHO)
% ============================================================
disp('--- Iniciando análise dinâmica dos parâmetros OMNI ---');

% === 1. Seleciona arquivo OMNI ===
if exist('filenameOmni','var') && isfile(filenameOmni)
    filename = filenameOmni;
else
    [file,path] = uigetfile({'*.txt;*.dat','Arquivos OMNI'});
    if isequal(file,0)
        disp('Arquivo OMNI não selecionado.');
        return;
    end
    filename = fullfile(path,file);
end

% === 2. Ler arquivo OMNI COM cabeçalho ===
opts = detectImportOptions(filename);
opts = setvartype(opts,'double');
omniTable = readtable(filename,opts);

% ============================================================
% === CRIA EIXO DE TEMPO REAL — FORMATO CIOM
% ============================================================
Year = omniTable.Year;
Day  = omniTable.Day;
Hour = omniTable.Hour;

if ismember("Min", omniTable.Properties.VariableNames)
    Min = omniTable.Min;
else
    Min = zeros(size(Year));
end

timeX_raw = datenum(datetime(Year,1,1) + days(Day-1) + hours(Hour) + minutes(Min));

% ============================================================
% === FILTRAR DIA DO OMNI PARA O MESMO PERÍODO DO CIOM
% ============================================================

%
fim_limite = floor(fim_plot) + eps;   % início do próximo dia sem incluir

maskOmni = (timeX_raw >= inicio_plot) & (timeX_raw <= fim_limite);

% Aplicar filtro
omniTable = omniTable(maskOmni,:);
timeX = timeX_raw(maskOmni);


% ============================================================
% === Remover variáveis de tempo
% ============================================================
remover = {'Year','Day','Hour','Min'};
existe = ismember(omniTable.Properties.VariableNames, remover);
omniVars = omniTable(:, ~existe);

% ============================================================
% === Remover colunas artificiais
% ============================================================
nomes = omniVars.Properties.VariableNames;
padroesRemover = contains(nomes, {'Extra','Var','Unnamed','Column'}, 'IgnoreCase', true);
nomes = nomes(~padroesRemover);
omniVars = omniVars(:, ~padroesRemover);

% ============================================================
% === Caixa de seleção (usuário escolhe quais parâmetros plotar)
% ============================================================
[idx, ok] = listdlg('PromptString','Selecione os parâmetros para plotar:', ...
    'ListString', nomes, 'SelectionMode','multiple','ListSize',[350 400]);

if ~ok
    disp('Nenhum parâmetro selecionado.');
    return;
end

% ============================================================
% === Criar FIGURA — igual CIOM
% ============================================================
figure(2); clf;
set(gcf,'Name','OMNI — Parâmetros Selecionados','NumberTitle','off');
set(gcf,'Position',[200 50 1600 900]);

maxPlots = 7;
subplotCounter = 0;

major = 4 * 0.2498;    % 1 dia
minor = 0.2498;        % 6 horas

% ============================================================
% === SUBPLOTS — IGUAIS AO MODELO CIOM
% ============================================================
for k = 1:numel(idx)

    nomeParam = nomes{idx(k)};
    y = omniVars.(nomeParam);

    if all(isnan(y)), continue; end

    subplotCounter = subplotCounter + 1;
    subplot(maxPlots,1,subplotCounter);

    % ===============================
    % === Linha azul CIOM
    % ===============================
    plot(timeX, y, 'b.-', 'LineWidth', 1.1);
    hold on;

    ax = gca;

    % ---------------------------------------------------------
    % === REMOVER A LINHA GROSSA DO MEIO (Major Grid) ===
    % ---------------------------------------------------------
    grid off;            % desliga grid
    ax.XGrid = 'off';
    ax.YGrid = 'off';
    ax.XMinorGrid = 'on';   % mantém grid menor fininho
    ax.YMinorGrid = 'on';

    % minor grid fino
    ax.MinorGridAlpha = 0.20;
    ax.MinorGridLineStyle = '-';
    ax.MinorGridColor = [0.6 0.6 0.6];

    % ---------------------------------------------------------
    % === Bordas CIOM ===
    % ---------------------------------------------------------
    ax.XAxis.LineWidth = 2;
    ax.YAxis.LineWidth = 2;
    ax.LineWidth = 2;
    ax.YColor = 'k';

    % ---------------------------------------------------------
    % === Ticks CIOM ===
    % ---------------------------------------------------------
    ax.XTick = inicio_plot : major : fim_limite;
    ax.XMinorTick = 'on';
    ax.XAxis.MinorTickValues = inicio_plot : minor : fim_limite;

    ax.TickDir = 'in';
    ax.TickLength = [0.01 0.01];

    % ---------------------------------------------------------
    % === Limites ===
    % ---------------------------------------------------------
    xlim([inicio_plot fim_limite]);
    ylim([min(y) max(y)]);

    ylabel(nomeParam, 'Interpreter', 'none');

    % ---------------------------------------------------------
    % === Último subplot mostra eixo X
    % ---------------------------------------------------------
    if k < numel(idx)
        set(gca,'XTickLabel',[]);
    else
        ax.XTick = inicio_plot : 1 : fim_plot;
        md = arrayfun(@(x) datestr(x,'mm/dd'), ax.XTick,'UniformOutput',false);
        ax.XTickLabel = md;
        xlabel('Time (Days)');
    end
end


% ======= ================================ =======%
% ======= ================================ =======%

function [m_out, d_out] = stretch_mean_std(m, d, N)

% Garante que desvio não tenha NaN
d(isnan(d)) = 0;

% Quantas repetições são necessárias para ultrapassar o tamanho N
k = ceil(N / length(m));

% Repete até ultrapassar
m_out = repmat(m(:), k, 1);
d_out = repmat(d(:), k, 1);

% Corta exatamente no comprimento desejado
m_out = m_out(1:N);
d_out = d_out(1:N);

end


