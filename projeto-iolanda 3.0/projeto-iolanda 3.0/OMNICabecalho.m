function omni_tratamento_manual
% ============================================================
% JANELA PRINCIPAL
% ============================================================
fig = uifigure('Name','ABRIR E TRATAR OMNI (Manual)', ...
    'Position',[300 100 700 520]);

% ============================================================
% TÍTULO
% ============================================================
uilabel(fig,'Text','TRATAMENTO DE DADOS OMNI', ...
    'FontSize',22,'FontWeight','bold', ...
    'Position',[160 470 400 40]);

% ============================================================
% PAINEL DE INSTRUÇÕES
% ============================================================
pnl = uipanel(fig,'Title','Instruções', ...
    'FontWeight','bold','FontSize',12,...
    'Position',[20 290 660 160]);

uilabel(pnl,'Text','Passo 1: Abra o site do OMNI e gere os arquivos', ...
    'FontSize',12,'Position',[15 100 400 25]);

uilabel(pnl,'Text','Passo 2: Baixe o TXT de PARÂMETROS (Create ASCII File)', ...
    'FontSize',12,'Position',[15 75 450 25]);

uilabel(pnl,'Text','Passo 3: Baixe o TXT de DADOS', ...
    'FontSize',12,'Position',[15 50 300 25]);

uilabel(pnl,'Text','Passo 4: Selecione os dois arquivos abaixo', ...
    'FontSize',12,'Position',[15 25 350 25]);

% Botão abrir site
uibutton(pnl,'Text','Abrir site OMNI', ...
    'FontWeight','bold',...
    'Position',[480 60 150 35], ...
    'ButtonPushedFcn', @(src,event)web('https://omniweb.gsfc.nasa.gov/form/omni_min.html','-browser'));


% ============================================================
% ÁREA DE SELEÇÃO DOS ARQUIVOS TXT
% ============================================================

% ------------ ARQUIVO DE PARÂMETROS --------------
uilabel(fig,'Text','Arquivo de PARÂMETROS:', ...
    'FontWeight','bold','Position',[20 240 200 25]);

edtHeader = uieditfield(fig,'text', ...
    'Position',[20 210 500 30], ...
    'Editable','off', ...
    'Value','Nenhum arquivo selecionado');

uibutton(fig,'Text','Selecionar', ...
    'Position',[530 210 150 30], ...
    'ButtonPushedFcn',@(src,event)selectHeader());

% ------------ ARQUIVO DE DADOS --------------
uilabel(fig,'Text','Arquivo de DADOS:', ...
    'FontWeight','bold','Position',[20 165 200 25]);

edtData = uieditfield(fig,'text', ...
    'Position',[20 135 500 30], ...
    'Editable','off', ...
    'Value','Nenhum arquivo selecionado');

uibutton(fig,'Text','Selecionar', ...
    'Position',[530 135 150 30], ...
    'ButtonPushedFcn',@(src,event)selectData());

% ============================================================
% BOTÃO PRINCIPAL - PROCESSAR
% ============================================================
uibutton(fig,'Text','PROCESSAR E SALVAR', ...
    'FontSize',16,'FontWeight','bold', ...
    'BackgroundColor',[0.1 0.5 0.1], 'FontColor','white', ...
    'Position',[230 50 240 50], ...
    'ButtonPushedFcn',@(src,event)processar());

% Variáveis internas armazenando os caminhos
headerFile = '';
dataFile = '';

% ============================================================
%  FUNÇÕES DE SELEÇÃO
% ============================================================
    function selectHeader()
        drawnow;
        uiwait(msgbox('Selecione o arquivo de PARÂMETROS e confirme.', ...
            'Selecionar arquivo', 'modal'));
        
        [f,p] = uigetfile({'*.txt','Arquivos TXT (*.txt)'}, ...
            'Selecione o arquivo de PARÂMETROS');
        
        if f ~= 0
            headerFile = fullfile(p,f);
            edtHeader.Value = headerFile;
        end
    end


    function selectData()
        drawnow;
        uiwait(msgbox('Selecione o arquivo de DADOS e confirme.', ...
            'Selecionar arquivo', 'modal'));
        
        [f,p] = uigetfile({'*.txt','Arquivos TXT (*.txt)'}, ...
            'Selecione o arquivo de DADOS');
        
        if f ~= 0
            dataFile = fullfile(p,f);
            edtData.Value = dataFile;
        end
    end


% ============================================================
%  BOTÃO PRINCIPAL DE PROCESSAMENTO
% ============================================================
    function processar()
        
        if isempty(headerFile) || isempty(dataFile)
            uialert(fig,'Selecione os dois arquivos TXT antes de continuar.','Erro');
            return;
        end
        try
            
            %=============================================================
            % FUNÇÃO PRINCIPAL: GERAR TXT TRATADO
            %=============================================================
            
            
            if isempty(headerFile) || isempty(dataFile)
                uialert(fig,'Selecione os DOIS arquivos para continuar.','Erro');
                return;
            end
            
            %----------------------------------------------------------
            % 1) Ler arquivo de parâmetros (cabeçalho)
            %----------------------------------------------------------
            rawHeader = fileread(headerFile);
            lines = splitlines(rawHeader);
            
            colNames = {};
            colIndex = [];
            
            for i = 1:numel(lines)
                line = strtrim(lines{i});
                if isempty(line), continue; end
                
                C = strsplit(line);
                
                % primeira coluna deve ser índice numérico (1,2,3,...)
                if ~isempty(regexp(C{1}, '^\d+$','once'))
                    idx = str2double(C{1});
                    fullName = strtrim(strjoin(C(2:end),' '));  % ex: 'Field magnitude average, nT'
                    fullNameLower = lower(fullName);
                    
                    % --------- MAPEAMENTO ESPECIAL (nomes bonitos) ----------
                    if contains(fullNameLower,'year')
                        ab = 'Year';
                    elseif contains(fullNameLower,'day')
                        ab = 'Day';
                    elseif contains(fullNameLower,'hour')
                        ab = 'Hour';
                    elseif contains(fullNameLower,'minute')
                        ab = 'Min';
                        
                        % IMF / Magnetic field
                    elseif contains(fullNameLower,'field magnitude') ...
                            || contains(fullNameLower,'imf magnitude')
                        ab = 'Fma';
                    elseif contains(fullNameLower,'bx')
                        ab = 'Bx';
                    elseif contains(fullNameLower,'by') && contains(fullNameLower,'gsm')
                        ab = 'ByG';
                    elseif contains(fullNameLower,'bz') && contains(fullNameLower,'gsm')
                        ab = 'BzG';
                    elseif contains(fullNameLower,'by') && contains(fullNameLower,'gse')
                        ab = 'ByE';
                    elseif contains(fullNameLower,'bz') && contains(fullNameLower,'gse')
                        ab = 'BzE';
                    elseif contains(fullNameLower,'sigma in imf magnitude')
                        ab = 'SigM';
                    elseif contains(fullNameLower,'sigma in imf vector')
                        ab = 'SigV';
                        
                        % Plasma
                    elseif contains(fullNameLower,'flow speed')
                        ab = 'Spe';
                    elseif contains(fullNameLower,'velocity') && contains(fullNameLower,'vx')
                        ab = 'Vx';
                    elseif contains(fullNameLower,'velocity') && contains(fullNameLower,'vy')
                        ab = 'Vy';
                    elseif contains(fullNameLower,'velocity') && contains(fullNameLower,'vz')
                        ab = 'Vz';
                    elseif contains(fullNameLower,'proton density')
                        ab = 'Den';
                    elseif contains(fullNameLower,'proton temperature')
                        ab = 'Pro';
                    elseif contains(fullNameLower,'flow pressure')
                        ab = 'Pre';
                    elseif contains(fullNameLower,'electric field') ...
                            || contains(fullNameLower,'ey')
                        ab = 'Ey';
                    elseif contains(fullNameLower,'plasma beta')
                        ab = 'Bet';
                    elseif contains(fullNameLower,'alfven mach')
                        ab = 'Amn';
                    elseif contains(fullNameLower,'magnetosonic mach')
                        ab = 'Mmn';
                        
                        % Spacecraft / BSN
                    elseif contains(fullNameLower,'spacecraft x')
                        ab = 'Scx';
                    elseif contains(fullNameLower,'spacecraft y')
                        ab = 'Scy';
                    elseif contains(fullNameLower,'spacecraft z')
                        ab = 'Scz';
                    elseif contains(fullNameLower,'bsn location x')
                        ab = 'Bsx';
                    elseif contains(fullNameLower,'bsn location y')
                        ab = 'Bsy';
                    elseif contains(fullNameLower,'bsn location z')
                        ab = 'Bsz';
                        
                        % Índices
                    elseif contains(fullNameLower,'ae index')
                        ab = 'AE';
                    elseif contains(fullNameLower,'al index')
                        ab = 'AL';
                    elseif contains(fullNameLower,'au index')
                        ab = 'AU';
                    elseif contains(fullNameLower,'sym/d')
                        ab = 'SYMd';
                    elseif contains(fullNameLower,'sym/h')
                        ab = 'SYMh';
                    elseif contains(fullNameLower,'asy/d')
                        ab = 'ASYd';
                    elseif contains(fullNameLower,'asy/h')
                        ab = 'ASYh';
                    elseif contains(fullNameLower,'polar cap') || ...
                            contains(fullNameLower,'pc index')
                        ab = 'PC';
                        
                        % Fluxo de prótons
                    elseif contains(fullNameLower,'proton flux') && contains(fullNameLower,'>10')
                        ab = 'F10';
                    elseif contains(fullNameLower,'proton flux') && contains(fullNameLower,'>30')
                        ab = 'F30';
                    elseif contains(fullNameLower,'proton flux') && contains(fullNameLower,'>60')
                        ab = 'F60';
                        
                    else
                        % fallback: primeiras 3 letras da primeira palavra
                        tokens = regexp(fullName,'[A-Za-z]+','match');
                        if isempty(tokens)
                            ab = sprintf('C%02d', idx);  % C01, C02, ...
                        else
                            base = tokens{1};
                            n = min(3, length(base));
                            ab = lower(base(1:n));
                            ab(1) = upper(ab(1));
                        end
                    end
                    
                    colIndex(end+1) = idx;
                    colNames{end+1} = ab;
                end
            end
            
            %----------------------------------------------------------
            % 2) Ler arquivo de dados
            %----------------------------------------------------------
            fid = fopen(dataFile);
            raw = textscan(fid, repmat('%f',1,max(colIndex)));
            fclose(fid);
            
            M = [raw{:}];
            M = M(:, 1:numel(colIndex));
            
            %----------------------------------------------------------
            % 3) Tratar valores inválidos do OMNI -> NaN
            %----------------------------------------------------------
            % --- Detecta valores faltantes do OMNI automaticamente ---
            for ii = 1:numel(M)
                val = M(ii);
                
                if isnan(val)
                    continue;
                end
                
                txt = strrep(sprintf('%.3f', val), '0', ''); % remove zeros p/ garantir
                txt = strrep(txt, '.', ''); % remove ponto
                
                % Se o valor for composto APENAS por dígitos '9'
                if all(txt == '9')
                    M(ii) = NaN;
                end
            end
            
            
            %----------------------------------------------------------
            % 4) Converter matriz para strings (para alinhar colunas)
            %----------------------------------------------------------
            strData = cell(size(M));   % cell de char
            
            for i = 1:size(M,1)
                for j = 1:size(M,2)
                    val = M(i,j);
                    
                    if j <= 4
                        % Primeiras 4 colunas ? inteiros
                        if isnan(val)
                            strData{i,j} = 'NaN';
                        else
                            strData{i,j} = sprintf('%d', round(val));
                        end
                    else
                        % Demais colunas
                        if isnan(val)
                            strData{i,j} = 'NaN';
                        else
                            nomeCol = upper(colNames{j});
                            % Índices geomagnéticos (sem .0)
                            isIndice = any(strcmp(nomeCol, ...
                                {'AE','AL','AU','SYMD','SYMH','ASYD','ASYH','PC','DST'}));
                            
                            if mod(val,1) ~= 0
                                % Tem decimal ? mantém
                                strData{i,j} = num2str(val);
                            else
                                % Inteiro
                                if isIndice
                                    % AE, AL, AU, SYM, ASY, PC ? sem .0
                                    strData{i,j} = sprintf('%d', round(val));
                                else
                                    % Não índice:
                                    % se valor bem grande, põe .1f, senão inteiro
                                    if abs(val) >= 1000
                                        strData{i,j} = sprintf('%.1f', val); % 203312.0
                                    else
                                        strData{i,j} = sprintf('%d', round(val));
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            %----------------------------------------------------------
            % 5) Calcular largura ideal por coluna
            %----------------------------------------------------------
            colWidths = zeros(1,size(strData,2));
            
            for j = 1:size(strData,2)
                lenData = cellfun(@length, strData(:,j));
                maxLenData = max(lenData);
                maxLen = max(maxLenData, length(colNames{j}));
                colWidths(j) = maxLen + 2; % +2 espaço
            end
            
            %----------------------------------------------------------
            % 6) Escrever arquivo final
            %----------------------------------------------------------
            [p,n,~] = fileparts(dataFile);
            newFile = fullfile(p, [n '_tratado.txt']);
            
            fid = fopen(newFile,'w');
            
            % Cabeçalho
            for j = 1:numel(colNames)
                fmt = sprintf('%%-%ds', colWidths(j));
                fprintf(fid, fmt, colNames{j});
            end
            fprintf(fid,'\n');
            
            % Dados
            for i = 1:size(strData,1)
                for j = 1:size(strData,2)
                    fmt = sprintf('%%-%ds', colWidths(j));
                    fprintf(fid, fmt, strData{i,j});
                end
                fprintf(fid,'\n');
            end
            
            fclose(fid);
            
            uialert(fig, sprintf('Arquivo criado:\n%s', newFile), ...
                'Sucesso','Icon','info');
            edit(newFile);
            
        catch ME
            uialert(fig, sprintf('Erro ao processar:\n%s', ME.message), ...
                'Erro','Icon','error');
        end
    end
end
    
        
