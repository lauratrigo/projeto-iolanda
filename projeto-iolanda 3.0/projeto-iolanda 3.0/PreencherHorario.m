% ========================================================================
%  SCRIPT: Corrige arquivos ionosféricos, preenche horários faltantes
%  - Grade fixa: 00:00:00 ? 23:55:00 (passo 5 min)
%  - Converte (“-”, “--”, “---”, vazio) ? NaN
%  - Mantém valores válidos
%  - Gera exatamente 289 linhas (1 cabeçalho + 288 dados)
% ========================================================================

clear; clc;

% === Selecionar pasta ====================================================
pasta = uigetdir(pwd, 'Selecione a pasta com os arquivos TXT');
if pasta == 0
    error('Nenhuma pasta selecionada.');
end

arquivos = dir(fullfile(pasta, '*.txt'));

if isempty(arquivos)
    error('Nenhum arquivo .txt encontrado.');
end

% === Loop nos arquivos ===================================================
for k = 1:length(arquivos)

    arquivo = fullfile(pasta, arquivos(k).name);
    fprintf('Processando: %s\n', arquivos(k).name);

    % === Lê arquivo original =============================================
    fid = fopen(arquivo, 'r');
    cabecalho = fgetl(fid);

    dados = textscan(fid, '%s %s %s %s %s %s', ...
        'Delimiter', ' ', 'MultipleDelimsAsOne', true);
    fclose(fid);

    % Campos crus
    dataStr = dados{1};
    dddStr  = dados{2};
    horaStr = dados{3};
    foF2str = dados{4};
    hFstr   = dados{5};
    hpF2str = dados{6};

    % === Converte valores para número (ou NaN) ============================
    foF2 = str2double(foF2str);  % "--", "-" e "" viram NaN
    hF   = str2double(hFstr);
    hpF2 = str2double(hpF2str);

    % === Converte data+hora para datetime ================================
    timestamp = datetime(strcat(dataStr, {' '}, horaStr), ...
        'InputFormat','yyyy.MM.dd HH:mm:ss');

    % === Arredonda horários para múltiplos de 5 min ======================
    minuto = minute(timestamp);
    minutoR = 5 * round(minuto / 5);
    timestamp = dateshift(timestamp,'start','minute') + minutes(minutoR - minuto);

    % === Cria grade fixa de 00:00 ? 23:55 ================================
    dataUnica = datetime(dataStr{1}, 'InputFormat','yyyy.MM.dd');
    inicio = dataUnica;                      % 00:00:00
    fim    = dataUnica + hours(23) + minutes(55);

    grade = (inicio:minutes(5):fim)';        % 288 horários

    % === Inicializa colunas com NaN ======================================
    foF2_full = nan(size(grade));
    hF_full   = nan(size(grade));
    hpF2_full = nan(size(grade));

    % === Preenche onde existe dado válido ================================
    [~, idx] = ismember(timestamp, grade);

    for i = 1:length(idx)
        if idx(i) ~= 0
            if ~isnan(foF2(i)), foF2_full(idx(i)) = foF2(i); end
            if ~isnan(hF(i)),   hF_full(idx(i))   = hF(i);   end
            if ~isnan(hpF2(i)), hpF2_full(idx(i)) = hpF2(i); end
        end
    end

    % === Texto para salvar =================================================
    dataTxt = datestr(grade,'yyyy.mm.dd');
    dddTxt  = dddStr{1};
    horaTxt = datestr(grade,'HH:MM:ss');

    % === Salvar arquivo corrigido =========================================
    novoNome = fullfile(pasta, [arquivos(k).name(1:end-4), '_corrigido.txt']);
    fid = fopen(novoNome, 'w');

    fprintf(fid, "%s\n", cabecalho);

    for i = 1:length(grade)
        fprintf(fid, '%s %s %s  %.3f   %.1f   %.1f\n', ...
            dataTxt(i,:), dddTxt, horaTxt(i,:), ...
            foF2_full(i), hF_full(i), hpF2_full(i));
    end

    fclose(fid);

    % === Verificação final (289 linhas) ===================================
    nlinhas = length(grade) + 1;  % +1 do cabeçalho
    if nlinhas ~= 289
        warning("Arquivo %s NÃO gerou 289 linhas!", arquivos(k).name);
    end

    fprintf('Arquivo salvo: %s (289 linhas)\n\n', novoNome);
end

fprintf('=== PROCESSAMENTO COMPLETO ===\n');
