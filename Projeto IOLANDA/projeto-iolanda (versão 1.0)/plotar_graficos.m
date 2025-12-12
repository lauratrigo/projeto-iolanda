clear all;        
close all;        
clc;              

prompt = {'Digite a sigla da estação (arg, jat, ou sjc):'};

titulo = 'Seleção de Estado';  
definput = {'arg'};            

resposta = inputdlg(prompt, titulo, [1 50], definput);

if isempty(resposta)
    msgbox('Nenhuma estação digitada.', 'Aviso', 'warn');  
    programas();   % volta para a tela principal do programa
    return;        % interrompe a função atual
end

palavraChave = lower(strtrim(resposta{1}));

if exist('hMsgbox','var') && ishandle(hMsgbox)
    delete(hMsgbox);
end

%hMsgbox = msgbox('Selecione a pasta que contém os arquivos (.txt).', 'Seleção de pasta');

pastaBase = uigetdir(pwd, 'Selecione a pasta principal');

if pastaBase == 0
    error('Nenhuma pasta selecionada.');  
    programas();   % volta para a tela principal do programa
    return;        % interrompe a função atual
end

if exist('hMsgbox','var') && ishandle(hMsgbox)
    delete(hMsgbox);
end

arquivos = dir(fullfile(pastaBase, '**', '*.txt'));

todosArquivos = fullfile({arquivos.folder}, {arquivos.name});

mask = contains(lower(todosArquivos), palavraChave);

arquivosEstacao = todosArquivos(mask);

if isempty(arquivosEstacao)
    msgbox(['Nenhum arquivo encontrado contendo "' palavraChave '" em ' pastaBase], ...
           'Aviso', 'warn');  % Mostra uma mensagem amigável
    programas();  % Volta para a tela principal do programa
    return;       % Sai da função atual
end

disp('Arquivos encontrados nesta estação:');
disp(strjoin(arquivosEstacao, newline));  

redutores = strings(0);  

for i = 1:numel(arquivosEstacao)  
    [~, nomeArquivo, ~] = fileparts(arquivosEstacao{i});

    partes = split(nomeArquivo, {'_', '-', ' '});
    partes = string(partes(~cellfun('isempty', partes)));
    
    idx = contains(lower(partes), palavraChave);
    
    if any(idx) 
        pos = find(idx);  
        for p = pos'
            if p > 1
                cand = partes(p-1);  
                if strlength(cand) > 2 && ~contains(lower(cand), palavraChave)
                    redutores(end+1) = upper(cand);  
                end
            end
            if p < numel(partes)
                cand = partes(p+1);  
                if strlength(cand) > 2 && ~contains(lower(cand), palavraChave)
                    redutores(end+1) = upper(cand);
                end
            end
        end
    end
end

redutores = unique(redutores);

if isempty(redutores)
    msgbox('Nenhum nome de redutor detectado automaticamente.', 'Aviso', 'warn');  
    programas();   % volta para o menu principal
    return;        % sai da função atual
else
    hMsgbox = msgbox(sprintf('Redutores encontrados: %s', strjoin(redutores, ', ')), 'Redutores detectados');

    % Depois de algum tempo ou ação do usuário, fecha a msgbox
    if exist('hMsgbox','var') && ishandle(hMsgbox)
        delete(hMsgbox);
    end
end

[indiceEscolhido, ok] = listdlg( ...
    'PromptString', 'Selecione o(s) redutor(es):', ...   
    'SelectionMode', 'multiple', ...                    
    'ListString', cellstr(redutores), ...                
    'Name', 'Seleção dos redutores', ...                  
    'ListSize', [400 300]);                             

if ~ok
    error('Nenhum redutor selecionado.');  
end

selecionados = {};      
arquivosRedutor = {};   

for r = redutores(indiceEscolhido)'  
    nomeRedutor = lower(strtrim(r));  
    maskR = contains(lower(arquivosEstacao), nomeRedutor);  
    arquivosR = arquivosEstacao(maskR);
    
    if isempty(arquivosR)
        continue;  
    end
    
    [idxArqs, okArqs] = listdlg( ...
        'PromptString', sprintf('Selecione os arquivos do redutor %s:', upper(nomeRedutor)), ...
        'SelectionMode', 'multiple', ...
        'ListString', arquivosR, ...
        'Name', sprintf('Arquivos de %s', upper(nomeRedutor)), ...
        'ListSize', [500 300]);  
    
    if okArqs
        arquivosRedutor = [arquivosRedutor, arquivosR(idxArqs)]; 
    end
end

selecionados = arquivosRedutor;  

if isempty(selecionados)
    msgbox('Nenhum arquivo foi selecionado.', 'Aviso', 'warn');  
    programas();   % volta para o menu principal
    return;        % sai da função atual
end

%msg = sprintf('Foram selecionados %d arquivo(s):\n', numel(selecionados));
%msg = [msg, strjoin(selecionados, newline)];  
%hMsgbox = msgbox(msg, 'Arquivos selecionados');  

if exist('hMsgbox','var') && ishandle(hMsgbox)
    delete(hMsgbox);
end

fileID = fopen(selecionados{1}, 'r');
dataTmp = textscan(fileID, '%s %s %s %f %f %f', ...
    'HeaderLines', 1, 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
fclose(fileID);

datetime_str = strcat(dataTmp{1}, {' '}, dataTmp{3});
tempoTotal = datetime(datetime_str, 'InputFormat', 'yyyy.MM.dd HH:mm:ss');

anoDetectado = mode(year(tempoTotal));

hMsgbox = msgbox(sprintf('Ano detectado automaticamente: %d\nPeríodo disponível: %s até %s', ...
    anoDetectado, datestr(min(tempoTotal)), datestr(max(tempoTotal))), ...
    'Informação sobre os dados');

if exist('hMsgbox','var') && ishandle(hMsgbox)
    delete(hMsgbox);
end

prompt = {'Mês (1-12):', 'Dia inicial:', 'Dia final:'};
titulo = 'Seleção de período de análise';
definput = {num2str(month(min(tempoTotal))), '1', num2str(day(max(tempoTotal)))};
resposta = inputdlg(prompt, titulo, [1 40], definput);

if isempty(resposta)
    msgbox('Nenhum período foi informado.', 'Aviso', 'warn');  
    programas();   % volta para a tela principal do programa
    return;        % interrompe a função atual
end

mesSelecionado  = str2double(resposta{1});
diaInicial      = str2double(resposta{2});
diaFinal        = str2double(resposta{3});

if any(isnan([mesSelecionado diaInicial diaFinal]))
    msgbox('Valores inválidos para o período.', 'Aviso', 'warn');  
    programas();   % volta para a tela principal
    return;        % interrompe a função atual
end

if diaFinal < diaInicial
    msgbox('O dia final não pode ser menor que o inicial.', 'Aviso', 'warn');  
    programas();   % volta para a tela principal
    return;        % interrompe a função atual
end

dadosFiltrados = [];
for i = 1:numel(selecionados)
    fileID = fopen(selecionados{i}, 'r');
    dataTmp = textscan(fileID, '%s %s %s %f %f %f', ...
        'HeaderLines', 1, 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
    fclose(fileID);
    
    datetime_str = strcat(dataTmp{1}, {' '}, dataTmp{3});
    tempo = datetime(datetime_str, 'InputFormat', 'yyyy.MM.dd HH:mm:ss');
    
    maskPeriodo = (month(tempo) == mesSelecionado) & ...
        (day(tempo) >= diaInicial) & (day(tempo) <= diaFinal);
    
    for j = 1:numel(dataTmp)
        dataTmp{j} = dataTmp{j}(maskPeriodo);
    end
    
    if isempty(dadosFiltrados)
        dadosFiltrados = dataTmp;
    else
        for j = 1:numel(dataTmp)
            dadosFiltrados{j} = [dadosFiltrados{j}; dataTmp{j}];
        end
    end
end

if isempty(dadosFiltrados{1})
    msgbox('Nenhum dado encontrado no período selecionado.', 'Aviso', 'warn');  
    programas();   % volta para a tela principal do programa
    return;        % interrompe a função atual
end

datetime_str = strcat(dadosFiltrados{1}, {' '}, dadosFiltrados{3});
tempoSelecionado = datetime(datetime_str, 'InputFormat', 'yyyy.MM.dd HH:mm:ss');
tempoSelecionado_num = datenum(tempoSelecionado);

disp(['Período selecionado: ' datestr(min(tempoSelecionado)) ' at? ' datestr(max(tempoSelecionado))]);

%hMsgbox = msgbox('Selecione o arquivo OMNI que contém o mesmo mês dos dados ionosféricos.', ...
    %'Seleção de OMNI');

if exist('hMsgbox','var') && ishandle(hMsgbox)
    delete(hMsgbox);
end

[arquivoOmni, caminhoOmni] = uigetfile({'*.txt','Arquivos de texto (*.txt)'}, ...
    'Selecione o arquivo OMNI do mesmo período');
if isequal(arquivoOmni,0)
    error('Nenhum arquivo OMNI selecionado.');
end
filenameOmni = fullfile(caminhoOmni, arquivoOmni);

dataOmni = readmatrix(filenameOmni, 'NumHeaderLines', 1);

diasNoMes = eomday(anoDetectado, mesSelecionado);
timeOmni = linspace(datenum(anoDetectado, mesSelecionado, 1), ...
    datenum(anoDetectado, mesSelecionado, diasNoMes+1), ...
    size(dataOmni,1));

inicio = datenum(anoDetectado, mesSelecionado, diaInicial);
fim    = datenum(anoDetectado, mesSelecionado, diaFinal+1);
maskOmni = (timeOmni >= inicio) & (timeOmni < fim);

dataOmniFiltrado = dataOmni(maskOmni, :);
timeOmniFiltrado = timeOmni(maskOmni);

% ============================================================
% LER CABEÇALHO PARA DESCOBRIR OS NOMES DAS COLUNAS
% ============================================================
fid = fopen(filenameOmni);
headerLine = fgetl(fid);             
fclose(fid);

cols = strsplit(strtrim(headerLine));   % vira {'Year','Day','Hour','Min','BzG',...}
M = dataOmniFiltrado;

findIdx = @(name) find(strcmpi(cols, name) | contains(lower(cols), lower(name)), 1);

iBz   = findIdx('Bz');     
iVsw  = findIdx('Spe');    
iNsw  = findIdx('Den');    
iAE   = findIdx('AE');     
iSymH = findIdx('SYMh');   

if isempty(iBz),   Bz   = NaN(size(M,1),1); else, Bz   = M(:,iBz);   end
if isempty(iVsw),  Vsw  = NaN(size(M,1),1); else, Vsw  = M(:,iVsw);  end
if isempty(iNsw),  Nsw  = NaN(size(M,1),1); else, Nsw  = M(:,iNsw);  end
if isempty(iAE),   AE   = NaN(size(M,1),1); else, AE   = M(:,iAE);   end
if isempty(iSymH), SymH = NaN(size(M,1),1); else, SymH = M(:,iSymH); end

hMsgbox = msgbox(sprintf('OMNI selecionado automaticamente de %02d/%02d at? %02d/%02d/%d', ...
    diaInicial, mesSelecionado, diaFinal, mesSelecionado, anoDetectado), ...
    'Período OMNI aplicado');

if exist('hMsgbox','var') && ishandle(hMsgbox)
    delete(hMsgbox);
end

timeOmniDatetime = datetime(timeOmniFiltrado, 'ConvertFrom', 'datenum');

if numel(selecionados) >= 1, filename1 = selecionados{1}; end
if numel(selecionados) >= 2, filename2 = selecionados{2}; else, filename2 = filename1; end
if numel(selecionados) >= 3, filename3 = selecionados{3}; else, filename3 = filename2; end

%hMsgbox = msgbox('Agora selecione o arquivo mediasedesvios.mat', 'Seleção do arquivo MAT');

if exist('hMsgbox','var') && ishandle(hMsgbox)
    delete(hMsgbox);
end

[arquivoMat, caminhoMat] = uigetfile({'*.mat','Arquivos MAT (*.mat)'}, ...
    'Selecione o arquivo mediasedesvios.mat');
filenameMat = fullfile(caminhoMat, arquivoMat);

fileID = fopen(filename1, 'r');  
data1 = textscan(fileID, '%s %s %s %f %f %f', ...
    'HeaderLines', 1, ...           
    'Delimiter', ' ', ...           
    'MultipleDelimsAsOne', true);   
fclose(fileID);                     

fileID = fopen(filename2, 'r');
data2 = textscan(fileID, '%s %s %s %f %f %f', 'HeaderLines', 1, ...
    'Delimiter', ' ', 'MultipleDelimsAsOne', true);
fclose(fileID);

fileID = fopen(filename3, 'r');
data3 = textscan(fileID, '%s %s %s %f %f %f', 'HeaderLines', 1, ...
    'Delimiter', ' ', 'MultipleDelimsAsOne', true);
fclose(fileID);

date_str = data1{1};    
time_str = data1{3};    

size(data1{6})
size(data2{6})
size(data3{6})


foF2 = nanmean([data1{4} data2{4} data3{4}], 2);  
hF   = nanmean([data1{5} data2{5} data3{5}], 2);  
hmF2 = nanmean([data1{6} data2{6} data3{6}], 2);  

inicio_plot = datenum(anoDetectado, mesSelecionado, diaInicial);
fim_plot    = datenum(anoDetectado, mesSelecionado, diaFinal + 1);

datetime_str = strcat(date_str, {' '}, time_str);
time = datetime(datetime_str, 'InputFormat', 'yyyy.MM.dd HH:mm:ss');
tempo_num = datenum(time);

maskPeriodo = (tempo_num >= inicio_plot) & (tempo_num < fim_plot);

time = time(maskPeriodo);
foF2 = foF2(maskPeriodo);
hF   = hF(maskPeriodo);
hmF2 = hmF2(maskPeriodo);

start_time = min(time);                   
end_time   = max(time);                      
full_time  = time;                        
full_time_numeric = datenum(full_time);     

disp(['Intervalo selecionado: ', datestr(start_time), ' at? ', datestr(end_time)]);

X0 = datenum(anoDetectado, mesSelecionado, diaInicial);
X1 = datenum(anoDetectado, mesSelecionado, diaFinal + 1);

XLIM_FIXO = [X0 X1];

XT_MAJOR = X0:1:X1;

if numel(XT_MAJOR) > 1
    XT_MINOR = XT_MAJOR(1:end-1) + 0.5;  
else
    XT_MINOR = X0 + 0.5;  
end

XT_LABELS = cellstr(datestr(XT_MAJOR, 'mm/dd'));

data = importdata(filenameOmni);                                 

M = dataOmniFiltrado;

fid = fopen(filenameOmni,'r');
headerLine = fgetl(fid);
fclose(fid);
cols = strsplit(strtrim(headerLine));

findIdx = @(name) find(strcmpi(cols,name) | contains(lower(cols), lower(name)), 1);

iBz   = findIdx('BzG');    
iVsw  = findIdx('Spe');   
iNsw  = findIdx('Den');   
iAE   = findIdx('AE');    
iSymH = findIdx('SYMh');  

disp("Encontrou SymH na coluna: " + iSymH);
if ~isempty(iSymH)
    disp("Nome real da coluna: " + cols{iSymH});
end

if isempty(iBz),   Bz   = NaN(size(M,1),1); else, Bz   = M(:,iBz); end
if isempty(iVsw),  Vsw  = NaN(size(M,1),1); else, Vsw  = M(:,iVsw); end
if isempty(iNsw),  Nsw  = NaN(size(M,1),1); else, Nsw  = M(:,iNsw); end
if isempty(iAE),   AE   = NaN(size(M,1),1); else, AE   = M(:,iAE); end
if isempty(iSymH), SymH = NaN(size(M,1),1); else, SymH = M(:,iSymH); end

time2 = timeOmniFiltrado;

full_foF2  = NaN(size(full_time));
full_hF    = NaN(size(full_time));
full_hmF2  = NaN(size(full_time));

[~, ia, ib] = intersect(full_time, time);
full_foF2(ia) = foF2(ib);
full_hF(ia)   = hF(ib);
full_hmF2(ia) = hmF2(ib);

if numel(full_foF2) >= 641
    full_foF2(641) = NaN;
    full_hF(641)   = NaN;
    full_hmF2(641) = NaN;
end

load(filenameMat, 'mediahF', 'desviohF', 'mediaf0F2', 'desviof0F2', 'mediahmF2', 'desviohmF2');

grayColor = [0.7, 0.7, 0.7];


% Cria a primeira figura para os gráficos
figureHandle1 = figure;  % A figura é criada e salva no handle
set(figureHandle1, 'Name', 'IOLANDA - Parâmetros Ionosféricos', 'NumberTitle', 'off');
set(figureHandle1, 'Tag', 'graficosIOLANDA');  % Define a tag para a figura
set(figureHandle1, 'CloseRequestFcn', @(src, event) fecharGraficos(src));  % Defina a função de fechamento
% Agora, seu código de gráfico
desviohmF2(isnan(desviohmF2)) = 0;
desviof0F2(isnan(desviof0F2)) = 0;
% ===================== SUBPLOT 1: Sym-H =======================
subplot(7,1,1);
plot(time2, SymH, '-b', 'LineWidth', 2);
hold on; grid on;
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
set(gca,'XTickLabel',[]);  
% ====================== SUBPLOT 2: h'F =======================
subplot(7,1,2);
plot(full_time_numeric, full_hF, '-b');
ax = gca;
ax.XAxis.LineWidth = 2;
hold on; grid on;

% ====== MÉDIAS E DESVIOS ======
N = length(full_time_numeric);
[mediahF, desviohF] = stretch_mean_std(mediahF, desviohF, N);

plot(full_time_numeric, mediahF, 'k-', 'LineWidth', 2);
fill_area_x = [full_time_numeric; flipud(full_time_numeric)];
fill_area_y = [mediahF + desviohF; flipud(mediahF - desviohF)];
fill(fill_area_x, fill_area_y, grayColor, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
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
% ==== CÁLCULO DINÂMICO DOS ÍNDICES NOTURNOS ====
t = full_time_numeric;
horaDecimal = mod(t - floor(t), 1) * 24;

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
diasTotal = days(max(time) - min(time)) + 1;
if diasTotal < 2
    step = 0.25; 
else
    step = 1;     
end
ax.XTick = min(full_time_numeric):step:max(full_time_numeric);
month_day = arrayfun(@(x) datestr(x, 'mm/dd'), ax.XTick, 'UniformOutput', false);
ax.XTickLabel = month_day;

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

fim_limite = floor(fim_plot) + eps;   

maskOmni = (timeX_raw >= inicio_plot) & (timeX_raw <= fim_limite);

omniTable = omniTable(maskOmni,:);
timeX = timeX_raw(maskOmni);

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
figureHandle2 = figure;  % Cria uma segunda figura
set(figureHandle2, 'Name', 'IOLANDA - OMNI: Parâmetros Selecionados', 'NumberTitle', 'off');
set(figureHandle2, 'Tag', 'graficosIOLANDA');  % Defina a tag para a segunda figura
set(figureHandle2, 'CloseRequestFcn', @(src, event) fecharGraficos(src));  % Mesma função de fechamento

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
    fim_limite = min(fim_limite, max(timeX_raw));  % Garantir que o fim_limite não ultrapasse o último valor de timeX_raw
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


