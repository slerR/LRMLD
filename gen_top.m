function sv_code = gen_top(file, cfg)
% generate a top module of list RMLD decoder
%
% cfg fields:
%   optional fields:
%       module_name - name of the top sv module. 
%       Default = 'top'
%
%       IS_PAD      - padding to L in make, 0 - no padding, 1 - padding. 
%       Default = 0
%
%       FSM         - type of the FSM, 0 - no FSM, 1 - FSM on N_U, 2 - FSM 
%       on N_COS, 3 - FSM on N_COS + FSM on merge tree in top_comb. 
%       Default = 0
%
%   required fields:
%       L     - list size
%       LLR_W - input LLR bit width
%       SECT  - sectionalization table as cell array 1 x A, A - number of
%       levels, each cell is an N x 2 matrix, N - number of modules on
%       level
%       MakeTables - tabels of the labels for make modules
%       CombTables - tabels of the node unation for comb modules  


    cfg    = set_default(cfg);
    nodes  = build_nodes(cfg);
    nodes  = link_tables(nodes, cfg);
    nodes  = find_children(nodes);
    nodes  = assign_params(nodes, cfg);
    nodes  = compute_latencies(nodes, cfg);

    sv_code = emit_sv(nodes, cfg);
    
    % write code 
    if ~isempty(file)
        fid = fopen(file, 'w');
        if fid < 0
            error('Could not open file: %s', file);
        end
        closer = onCleanup(@() fclose(fid));
        fprintf(fid, '%s', sv_code);
    end
end

    % defaults params
    function cfg = set_default(cfg)
        if ~isfield(cfg,'module_name')|| isempty(cfg.module_name)
            cfg.module_name = 'top';
        end
        if ~isfield(cfg,'IS_PAD')|| isempty(cfg.IS_PAD)
            cfg.IS_PAD = 0;
        end
        if ~isfield(cfg,'FSM')|| isempty(cfg.FSM)
            cfg.FSM = 0;
        end

        required = {'L', 'LLR_W', 'SECT', 'MakeTables', 'CombTables'};
        for i = 1:numel(required)
            if ~isfield(cfg, required{i}) || isempty(cfg.(required{i}))
                error('%s value is required', required{i});
            end
        end
    end

    % select type of module for each section, make SECT table redefinition
    function nodes = build_nodes(cfg)
        levels = cfg.SECT;
        node = struct('id', {}, 'level', {}, 'start', {}, 'stop', {}, 'span', ...
                      {}, 'key', {}, 'type', {}, 'children', {}, 'isRoot', {}, ...
                      'tableKey', {}, 'table', {}, 'tableInfo', {}, 'labelW', ...
                      {}, 'metricW', {}, 'outCount', {}, 'latency', {}, 'ready', ...
                      {}, 'delayL', {}, 'delayR', {}, 'instName', {}, 'sigBase', {} );
        id = 0;
        for i = 1:numel(levels)
            sect = levels{i};
            if size(sect,2) ~= 2
               error('Each SECT level must be an N x 2 matrix.');
            end
            for j = 1:size(sect,1)
                id = id + 1;
                nodes(id).id       = id;
                nodes(id).level    = i;
                nodes(id).start    = sect(j,1);
                nodes(id).stop     = sect(j,2);
                nodes(id).span     = sect(j,2) - sect(j,1);
                nodes(id).key      = sprintf('%d_%d', nodes(id).start, nodes(id).stop);
                nodes(id).type     = "";
                nodes(id).children = [];
                nodes(id).isRoot   = false;
                nodes(id).tableKey = 'default';
                nodes(id).delayL   = 0;
                nodes(id).delayR   = 0;
            end
        end
        
        % module type definition
        for i = 1:numel(nodes)
            seen_start = false;
            for j = 1:i-1
                if nodes(j).start == nodes(i).start
                    seen_start = true;
                    break;
                end
            end
            if ~seen_start
                nodes(i).type = "make";
            else
                nodes(i).type = "comb";
            end
        end
        nodes(end).isRoot = true;
    end

    function nodes = link_tables(nodes, cfg)
        for i = 1:numel(nodes)
            if nodes(i).type == "make"
                key = find_key(cfg.MakeTables, nodes(i).key);
                nodes(i).tableKey = key;
                tbl = find_table(cfg.MakeTables, key);
                nodes(i).tableInfo = form_make_table(tbl);
            else
                key = find_key(cfg.CombTables, nodes(i).key);
                nodes(i).tableKey = key;
                tbl = find_table(cfg.CombTables, key);
                nodes(i).tableInfo = form_comb_table(tbl);
            end
        end
    end


    
% help function for link_tables
    % find uniq key in table, if no certain key - use defaul table 
    function key = find_key(list, nodeKey)
        key = 'default'; 
        for k = 1:numel(list)
            kx = char(list(k).key);
            if strcmp(kx, nodeKey)
                key = kx;
                return;
            end
        end
    end
    
    % find appropriate table
    function tbl = find_table(list, key)
        tbl = [];
        for k = 1:numel(list)
            if strcmp(char(list(k).key), key)
                tbl = list(k).table;
                return; 
            end
        end
        for k = 1:numel(list)
            if strcmp(char(list(k).key), 'default')
                tbl = list(k).table;
                return;
            end
        end
    end
%% find children tables for comb and top_comb
    function nodes = find_children(nodes)        
        for i = 1:numel(nodes)
            if nodes(i).type == "make"
                continue;
            end

            parent = nodes(i);   
            found = false;

            for a = 1:i-1
                if nodes(a).start ~= parent.start
                    continue;
                end
                for b = 1: i-1
                    if nodes(b).stop ~= parent.stop
                        continue;
                    end

                    if nodes(a).stop == nodes(b).start
                        nodes(i).children = [a, b];
                        found = true;
                        break;
                    end
                end
                if found
                    break;
                end
            end
            if ~found        
                error('Could not find sections for unation in [%d %d]', ...
                parent.start, parent.stop)
            end
        end
    end
%% сalculate main parameters of modules
    function nodes = assign_params(nodes, cfg)
        makeW = [];
        for i = 1:numel(nodes)
            if nodes(i).type == "make"
                makeW(end+1) = nodes(i).tableInfo.width; %#ok<AGROW>
            end
        end
        globalLabelW = max(makeW);
        globalMetricW = cfg.LLR_W + ceil(log2(globalLabelW));

        for i = 1:numel(nodes)
            nodes(i).metricW = globalMetricW;
            if nodes(i).type == "make"
               nodes(i).labelW = nodes(i).tableInfo.width;               
               if ~cfg.IS_PAD
                   nodes(i).outCount = nodes(i).tableInfo.N_COD;
               else
                   nodes(i).outCount = cfg.L;
               end
               nodes(i).instName = sprintf('make_%s', nodes(i).key);
               nodes(i).sigBase  = sprintf('m_m_%s', nodes(i).key);
            else
               left  = nodes(nodes(i).children(1));
               right = nodes(nodes(i).children(2));
               nodes(i).labelW = left.labelW + right.labelW;
               if nodes(i).isRoot
                  nodes(i).outCount = cfg.L;
                  nodes(i).instName = 'top_comb';
                  nodes(i).sigBase  = 'top';
               else
                  [nodes(i).outCount, ~] = comb_out_count(left.outCount, right.outCount, cfg.L);
                  nodes(i).instName = sprintf('comb_%s', nodes(i).key);
                  nodes(i).sigBase  = sprintf('m_c_%s', nodes(i).key);
               end
            end
        end
    end
%% compute latencies
    function nodes = compute_latencies(nodes, cfg)
        for i = 1:numel(nodes)
            if nodes(i).type == "make"
                nodes(i).latency = make_latency(nodes(i).span,...
                nodes(i).tableInfo.N_COD);
                
                nodes(i).ready = nodes(i).latency;
            else
                left = nodes(nodes(i).children(1));
                right = nodes(nodes(i).children(2));

                nodes(i).latency = comb_latency(cfg.FSM, left.outCount,...
                right.outCount, cfg.L, nodes(i).tableInfo.N_COS,...
                nodes(i).tableInfo.N_U);

                parentIn =  max(left.ready, right.ready);
                nodes(i).delayL = parentIn - left.ready;
                nodes(i).delayR = parentIn - right.ready;
                nodes(i).ready = parentIn + nodes(i).latency;
            end
        end
    end

    function Lat = make_latency(span, N_COD)
        Lat = ceil(log2(span))+2;
        if N_COD < 3
            Lat = Lat+1;
        elseif N_COD < 5
            Lat = Lat+2;
        else
            Lat = Lat+6;
        end
    end

    function Lat = comb_latency(FSM, n, n1, L, N_COS, N_U)
        [nout, total_comb] = comb_out_count(n, n1, L);
        if FSM == 0
            if (n >= L) && (n1 >= L)
                n_blocks = ceil(L/4);
                Lat = 1+1+ceil(log2(N_U))*ceil(log2(2*nout));
                if n_blocks == 1
                    Lat = Lat+3;
                elseif n_blocks == 2
                    Lat = Lat+7;
                elseif n_blocks == 3
                    Lat = Lat+11;
                else
                    Lat = Lat+13;
                end
            else        
                Lat = 4+ceil(log2(total_comb))*(ceil(log2(total_comb))+1)/2+...
                      1+ceil(log2(N_U))*ceil(log2(2*nout));
            end
        elseif FSM == 1
            if (n >= L) && (n1 >= L)
                n_blocks = ceil(L/4);
                Lat = 1+1+ceil(log2(N_U))*ceil(log2(2*nout))+N_U;
                if n_blocks == 1
                    Lat = Lat+3;
                elseif n_blocks == 2
                    Lat = Lat+7;
                elseif n_blocks == 3
                    Lat = Lat+11;
                else
                    Lat = Lat+13;
                end
            else
                Lat = 4+ceil(log2(total_comb))*(ceil(log2(total_comb))+1)/2+...
                      1+ceil(log2(N_U))*ceil(log2(2*nout)) + N_U;
            end
        else
            if (n >= L) && (n1 >= L)
                n_blocks = ceil(L/4);
                Lat = 1+1+ceil(log2(N_U))*ceil(log2(2*nout))+ N_COS + 1;
                if n_blocks == 1
                    Lat = Lat+3;
                elseif n_blocks == 2
                    Lat = Lat+7;
                elseif n_blocks == 3
                    Lat = Lat+11;
                else
                    Lat = Lat+13;
                end
            else
                Lat = 4+ceil(log2(total_comb))*(ceil(log2(total_comb))+1)/2+...
                      1+ceil(log2(N_U))*ceil(log2(2*nout)) + N_COS + 1;
            end
        end 
    end

    
    % help function for assign_params - calculating L_OUT for comb
    function [nout, total_comb] = comb_out_count(n, n1, L)
        if (n >= L) && (n1 >= L)
            nout = L; 
            total_comb = L;
            return;
        end
        if (n*n1) < L
            nout = n*n1; 
            total_comb = nout;
            return;
        end
        
        if L <=4
            n_lim  = 2;
            n1_lim = 2;
        elseif L <=6
            n_lim  = 2;
            n1_lim = 3;
        elseif L <=9
            n_lim  = 3;
            n1_lim = 3;
        elseif L <=12
            n_lim  = 3;
            n1_lim = 4;
        else
            n_lim  = 4;
            n1_lim = 4;
        end
        
        total_comb = n_lim*n1_lim;
        if total_comb > L
            nout = L;
        else
            nout = total_comb;
        end
    end

%% form tables for make and comb
    function info = form_make_table(tbl)
        if isstring(tbl)
            tbl = cellstr(tbl);
        else
            error('Make table must be string array')
        end

        [rows, cols] = size(tbl);
        w = 0;
        cleaned_tbl = cell(rows, cols);
        for i = 1:rows
            for j = 1:cols
                s = regexprep(char(tbl{i,j}), '[^01]', '');
                cleaned_tbl{i,j} = s;
                w = max(w, numel(s));
            end
        end

        if w == 0
            error('Make table does not contain labels')
        end

        lit = cell(rows, cols);
        for i = 1:rows
            for j = 1:cols
                lit{i,j} = sprintf('%d''b%s',w, char(cleaned_tbl{i,j}));
            end
        end

        info.kind    = 'make';
        info.rows    = rows; 
        info.cols    = cols;
        info.width   = w; 
        info.lit = lit;
        info.N_COS   = rows; 
        info.N_COD   = cols;
    end

    function info = form_comb_table(tbl)
        if ~isnumeric(tbl) || size(tbl,2) ~= 3
            error('Comb table must be numeric N x 3 matrix [new left right]')
        end
        new_idx = tbl(:, 1);
        l_idx   = tbl(:, 2);
        r_idx   = tbl(:, 3);
        
        N_COS = max(new_idx)+1;
        counts = accumarray(new_idx+1,1,[N_COS,1]);
        N_U    = counts(1);
        idx_w  = ceil(log2(double(N_COS)));

        lit = cell(N_COS, N_U);

        for i = 0:N_COS-1
            rows = find(new_idx == i);
            for j = 1:N_U
                li = dec2bin(l_idx(rows(j)), idx_w);
                ri = dec2bin(r_idx(rows(j)), idx_w);
                lit{i+1, j} = sprintf('%d''b%s_%s', 2*idx_w, li, ri);
            end
        end
        info.kind  = 'comb';
        info.rows  = N_COS;
        info.cols  = N_U;
        info.idx_w = idx_w;
        info.lit   = lit;
        info.N_COS = N_COS;
        info.N_U   = N_U;
    end
%% print sv code to file
    function sv = emit_sv(nodes, cfg)
        makeInfos = {}; combInfos = {};
        for i = 1:numel(nodes)
            if nodes(i).type == "make"
                makeInfos{end+1} = nodes(i).tableInfo;%#ok<AGROW>
            else
                combInfos{end+1} = nodes(i).tableInfo;%#ok<AGROW> 
            end
        end
        globalN_COS = makeInfos{1}.N_COS;
        maxLabelW = max(cellfun(@(x) x.width, makeInfos));

        makeNames = unique_table_names(nodes, "make", "DECOMP");
        combNames = unique_table_names(nodes, "comb", "TBL");

        lines        = {};
        lines{end+1} = sprintf('module %s #(', cfg.module_name);
        lines{end+1} = sprintf('    parameter     L           = %d,', cfg.L);
        lines{end+1} = sprintf('    parameter     LLR_W       = %d,', cfg.LLR_W);
        lines{end+1} = sprintf('    parameter     IS_PAD      = %d,', cfg.IS_PAD);
        lines{end+1} = sprintf('    parameter logic [1:0] FSM = 2''b%s,', dec2bin(cfg.FSM, 2));
        lines{end+1} = sprintf('    localparam     MLABEL_W   = %d,', maxLabelW);
        lines{end+1} = sprintf('    localparam     METRIC_W   = LLR_W + $clog2(MLABEL_W)');
        lines{end+1} = sprintf(')(');
        lines{end+1} = sprintf('    input  logic                            clk,');
        lines{end+1} = sprintf('    input  logic                            i_v,');
        lines{end+1} = sprintf('    input  logic signed  [   LLR_W - 1 : 0] i_llr [0 : %d   ],', nodes(end).stop - 1);
        lines{end+1} = sprintf('    output logic         [METRIC_W - 1 : 0] o_m   [0 : L - 1],');
        lines{end+1} = sprintf('    output logic         [          %d : 0] o_l   [0 : L - 1],', nodes(end).stop - 1);
        lines{end+1} = sprintf('    output logic                            o_v');
        lines{end+1} = sprintf(');');
        lines{end+1} = sprintf('');
        lines{end+1} = sprintf('    localparam N_COS = %d;', globalN_COS);
        lines{end+1} = sprintf('');

        for i = 1:numel(makeNames)
            n = find_node_by_table_key(nodes, "make", makeNames(i).key);
            lines = [lines, emit_make_table(makeNames(i).name, n.tableInfo)]; %#ok<AGROW>
            lines{end+1} = sprintf('');
        end
        for i = 1:numel(combNames)
            n = find_node_by_table_key(nodes, "comb", combNames(i).key);
            lines = [lines, emit_comb_table(combNames(i).name, n.tableInfo)]; %#ok<AGROW>
            lines{end+1} = sprintf('');
        end

        for i = 1:numel(nodes)
            n = nodes(i);
            if n.isRoot
                continue;
            end
            [mW, lW] = node_pack_widths(n);
            lines{end+1} = sprintf('    logic [%d - 1 : 0] %s_m [0 : N_COS - 1];', mW, n.sigBase);
            lines{end+1} = sprintf('    logic [%d - 1 : 0] %s_l [0 : N_COS - 1];', lW, n.sigBase);
            lines{end+1} = sprintf('    logic              %s_v;', n.sigBase);
            lines{end+1} = sprintf('');
        end
        
        % Top FSM specific evaluation
        lines{end+1} = '    localparam logic [1:0] TOP_FSM = (FSM == 2''b00) ? 2''b00 : (FSM == 2''b01) ? 2''b00 : (FSM == 2''b10) ? 2''b01 : 2''b10;';
        lines{end+1} = '';

        for i = 1:numel(nodes)
            n = nodes(i);
            if n.type == "make"
                lines = [lines, emit_make_instance(n, nodes, cfg, makeNames)]; %#ok<AGROW>
            else
                lines = [lines, emit_comb_instance(n, nodes, cfg, combNames)]; %#ok<AGROW>
            end
            lines{end+1} = sprintf('');
        end
        
        lines{end+1} = sprintf('endmodule');
        lines{end+1} = sprintf('');
        lines{end+1} = sprintf('`timescale 1ns / 1ps');

        sv = strjoin(lines, newline);
    end

    % help functions for print sv code
    function nameMap = unique_table_names(nodes, kind, prefix)
        nameMap = struct('key', {}, 'name', {});
        seen = {};
        for i = 1:numel(nodes)
            if nodes(i).type ~= kind
               continue;
            end
            key = nodes(i).tableKey;
            if any(strcmp(seen, key))
               continue;
            end
            seen{end+1} = key; %#ok<AGROW>
            nameMap(end+1).key = key; %#ok<AGROW>
            nameMap(end).name = sprintf('%s_%d', prefix, numel(seen)-1);
        end
    end

    function n = find_node_by_table_key(nodes, kind, key)
        for i = 1:numel(nodes)
            if nodes(i).type == kind && strcmp(nodes(i).tableKey, key)
                n = nodes(i);
                return;
            end
        end
    end   

    function lines = emit_comb_table(name, info)
        lines = {};
        lines{end+1} = sprintf('    localparam logic [%d - 1 : 0] %s [0 : %d - 1][0 : %d - 1] = ''{', 2*info.idx_w, name, info.rows, info.cols);
        for r = 1:info.rows
            lines{end+1} = sprintf('        ''{%s}%s', strjoin(info.lit(r,:), ', '), get_comma(r < info.rows));
        end
        lines{end+1} = sprintf('    };');
    end

    function lines = emit_make_instance(n, ~, ~, makeNames)
        tblName = table_symbol_name(makeNames, n.tableKey);
        lines = {
            sprintf('    make#('), ...
            sprintf('        .LLR_W   (LLR_W          ),'), ...
            sprintf('        .LABEL_W (%d             ),', n.labelW), ...
            sprintf('        .N_COS   (N_COS          ),'), ...
            sprintf('        .N       (%d             ),', n.tableInfo.N_COD), ...
            sprintf('        .DECOMP  (%s             ),', tblName), ...
            sprintf('        .IS_PAD  (IS_PAD         ),'), ...
            sprintf('        .METRIC_W(METRIC_W       )'), ...
            sprintf('    )%s (', n.instName), ...
            sprintf('        .clk      (clk            ),'), ...
            sprintf('        .i_valid  (i_v            ),'), ...
            sprintf('        .i_llr    (i_llr[%d : %d] ),', n.start, n.stop - 1), ...
            sprintf('        .o_metrics(%s_m           ),', n.sigBase), ...
            sprintf('        .o_labels (%s_l           ),', n.sigBase), ...
            sprintf('        .o_valid  (%s_v           )', n.sigBase), ...
            sprintf('    );')
            };
    end
    
    function lines = emit_make_table(name, info)
        lines = {};
        lines{end+1} = sprintf('    localparam logic [%d - 1 : 0] %s [0 : %d - 1][0 : %d - 1] = ''{', info.width, name, info.rows, info.cols);
        for r = 1:info.rows
            lines{end+1} = sprintf('        ''{%s}%s', strjoin(info.lit(r,:), ', '), get_comma(r < info.rows));
        end
        lines{end+1} = sprintf('    };');
    end

    function lines = emit_comb_instance(n, nodes, ~, combNames)
        left = nodes(n.children(1));
        right = nodes(n.children(2));
        lines = {};

        if n.delayL > 0, lines = [lines, emit_delay_block(left, n)]; end %#ok<AGROW>
        if n.delayR > 0, lines = [lines, emit_delay_block(right, n)]; end %#ok<AGROW>

        [leftM, leftL, leftV] = child_signal_refs(left, n);
        [rightM, rightL, rightV] = child_signal_refs(right, n);

        if n.isRoot
            modName = 'top_comb';
            outM = 'o_m'; outL = 'o_l'; outV = 'o_v';
            fsmExpr = 'TOP_FSM';
        else
            modName = 'comb';
            outM = sprintf('%s_m', n.sigBase); outL = sprintf('%s_l', n.sigBase); outV = sprintf('%s_v', n.sigBase);
            fsmExpr = 'FSM'; % Safely converts 2-bit FSM to 1-bit IS_FSM
        end

        tblName = table_symbol_name(combNames, n.tableKey);

        lines{end+1} = sprintf('    %s#(', modName);
        lines{end+1} = sprintf('        .L        (L            ),');
        lines{end+1} = sprintf('        .FSM      (%s           ),', fsmExpr);
        lines{end+1} = sprintf('        .N        (%d           ),', left.outCount);
        lines{end+1} = sprintf('        .N1       (%d           ),', right.outCount);
        lines{end+1} = sprintf('        .N_COS    (N_COS        ),');
        lines{end+1} = sprintf('        .METRIC_W (METRIC_W     ),');
        lines{end+1} = sprintf('        .LABEL_W  (%d           ),', left.labelW);
        lines{end+1} = sprintf('        .LABEL_W1 (%d           ),', right.labelW);
        lines{end+1} = sprintf('        .N_OUT    (%d           ),', n.outCount);
        lines{end+1} = sprintf('        .CONC_W   (%d           )%s', left.labelW + right.labelW, get_comma(~n.isRoot));

        if ~n.isRoot
            lines{end+1} = sprintf('        .N_U      (%d           ),', n.tableInfo.N_U);
            lines{end+1} = sprintf('        .TBL      (%s           )', tblName);
        end
        lines{end+1} = sprintf('    )%s (', n.instName);
        lines{end+1} = sprintf('        .clk        (clk        ),');
        lines{end+1} = sprintf('        .i_valid    (%s & %s    ),', leftV, rightV);
        lines{end+1} = sprintf('        .i_metrics  (%s         ),', leftM);
        lines{end+1} = sprintf('        .i_labels   (%s         ),', leftL);
        lines{end+1} = sprintf('        .i_metrics1 (%s         ),', rightM);
        lines{end+1} = sprintf('        .i_labels1  (%s         ),', rightL);
        lines{end+1} = sprintf('        .o_metrics  (%s         ),', outM);
        lines{end+1} = sprintf('        .o_labels   (%s         ),', outL);
        lines{end+1} = sprintf('        .o_valid    (%s         )', outV);
        lines{end+1} = sprintf('    );');
    end

    function s = table_symbol_name(nameMap, key)
        for i = 1:numel(nameMap)
            if strcmp(nameMap(i).key, key)
                s = nameMap(i).name; 
                return;
            end
        end
        error('Table symbol not found for key %s.', key);
    end

    function [mRef, lRef, vRef] = child_signal_refs(child, parent)
        if parent.children(1) == child.id
           delay = parent.delayL;
        else
           delay = parent.delayR;
        end
        if delay == 0
            mRef = sprintf('%s_m', child.sigBase);
            lRef = sprintf('%s_l', child.sigBase);
            vRef = sprintf('%s_v', child.sigBase);
        else
            alias = sprintf('d_%s_to_%s', child.key, parent.key);
            mRef = sprintf('%s_m', alias);
            lRef = sprintf('%s_l', alias);
            vRef = sprintf('%s_v', alias);
        end
    end

    function lines = emit_delay_block(child, parent)
        if parent.children(1) == child.id
            delay = parent.delayL;
        else
            delay = parent.delayR;
        end
        if delay <= 0
            lines = {};
            return;
        end
        
        alias = sprintf('d_%s_to_%s', child.key, parent.key);
        [mW, lW] = node_pack_widths(child);
        
        lines = {
        sprintf('    logic [%d - 1 : 0] %s_m [0 : N_COS - 1];', mW, alias), ...
        sprintf('    logic [%d - 1 : 0] %s_l [0 : N_COS - 1];', lW, alias), ...
        sprintf('    logic              %s_v;\n', alias), ... % <--- ДОБАВЛЕН alias
        sprintf('    list_delay#('), ...
        sprintf('        .DELAY(%d   ),', delay), ...
        sprintf('        .N_OUT(N_COS),'), ...
        sprintf('        .WIDTH(%d   )', mW), ...
        sprintf('    )delay_%s_m (', alias), ...
        sprintf('        .clk    (clk ),'), ...
        sprintf('        .i_data (%s_m),', child.sigBase), ...
        sprintf('        .o_data (%s_m)', alias), ...
        sprintf('    );\n'), ...
        sprintf('    list_delay #('), ...
        sprintf('        .DELAY(%d   ),', delay), ...
        sprintf('        .N_OUT(N_COS),'), ...
        sprintf('        .WIDTH(%d   )', lW), ...
        sprintf('    ) delay_%s_l (', alias), ...
        sprintf('        .clk    (clk ),'), ...
        sprintf('        .i_data (%s_l),', child.sigBase), ...
        sprintf('        .o_data (%s_l)', alias), ...
        sprintf('    );\n'), ...
        sprintf('    logic [0:0] %s_v_in [0:0];', alias), ...
        sprintf('    logic [0:0] %s_v_out [0:0];', alias), ...
        sprintf('    assign %s_v_in[0] = %s_v;\n', alias, child.sigBase), ...
        sprintf('    list_delay #('), ...
        sprintf('        .DELAY(%d),', delay), ...
        sprintf('        .N_OUT(1 ),'), ...
        sprintf('        .WIDTH(1 )'), ...
        sprintf('    ) delay_%s_v (', alias), ...
        sprintf('        .clk    (clk    ),'), ...
        sprintf('        .i_data (%s_v_in),', alias), ...
        sprintf('        .o_data (%s_v_out)', alias), ... 
        sprintf('    );'), ...
        sprintf('    assign %s_v = %s_v_out[0];', alias, alias) 
        };
    end

    function [mW, lW] = node_pack_widths(n)
        mW = n.outCount * n.metricW;
        lW = n.outCount * n.labelW;
    end

    function c = get_comma(cond)
        if cond
            c = ',';
        else
            c = '';
        end
    end
%%
