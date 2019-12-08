%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                     %
%     writeLatexCV  02/12/2019                                        %
%                                                                     %
% File name:        texFormat_win1252.m                               %
% File type:        Function                                          %
% File description: Specific symbols in windows-1252 encode           %
% File version:     1.1.0                                             %
%                                                                     %
% Author: Carles Mesado                                               %
% E-mail: mesado31@gmail.com                                          %
%                                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function text = texFormat_win1252(text)
    %
    % WARNING: DO NOT save this file using unix OS
    % translate some special characters into latex
    %
    % load global variables
    global args
    %keep original line
    text_org = text;
    %forbiden symbols
%     for c = '%#+'
%         if ~isempty(strfind(text, c))
%             terminateProg('texFormat_win1252::forbiddenCharacter', horzcat('Forbidden character ''', c, ''' is found in line'), text_org)
%         end
%     end
    %char % could not be found because they are all removed in preProcessInputFile
    %char # and + sould be fine in text as long as they are not at the
    %beginning of the line, in such case an error is probably thrown
    %Symbols allowed in textmode !�?;:,.'�/*-=()[]
    %this symbols must be translated first
    text = strrep(text, '\', '\textbackslash ');
    text = strrep(text, '{', '\{');
    text = strrep(text, '}', '\}');
    %translate superscripts
    for tmp = regexp(text, '\^\\{.*?\\}', 'match') %greedy expression
        if ~isempty(strfind(tmp{1}(4:end-2), '^\{'))
            terminateProg('texFormat_utf8::nestedSuperscript', 'Superscripts cannot be nested, see line', text_org)
        end
        text = strrep(text, tmp{1}, strcat('\textsuperscript{', tmp{1}(4:end-2), '}'));
    end
    %translate subscripts
    for tmp = regexp(text, '_\\{.*?\\}', 'match')  %greedy expression
        if ~isempty(strfind(tmp{1}(4:end-2), '_\{'))
            terminateProg('texFormat_utf8::nestedSubscript', 'Subscripts cannot be nested, see line', text_org)
        end
        text = strrep(text, tmp{1}, strcat('\textsubscript{', tmp{1}(4:end-2), '}'));
    end
    %symbols with equivalent latex command
    text = strrep(text, '� ', '\textdegree\ '); text = strrep(text, '�', '\textdegree ');
    text = strrep(text, '~', '\textasciitilde ');
    text = strrep(text, '^', '\textasciicircum ');
    text = strrep(text, '|', '\textbar ');
    text = strrep(text, '<', '\textless ');
    text = strrep(text, '>', '\textgreater ');
    %escape symbols
    text = strrep(text, '_', '\_');
    text = strrep(text, '&', '\&');
    text = strrep(text, '#', '\#');
    %other symbols
    text = strrep(text, '�', '!`');
    text = strrep(text, '"', '''''');
    text = strrep(text, '�', '\textsuperscript{a}');
    %currency symbols
    text = strrep(text, '$', '\textdollar ');
    text = strrep(text, '�', '\textsterling ');
    text = strrep(text, '�', '\textyen ');
    %marvosym symbols not used under windowsOS
    %at symbol can be written jast as @, but the default latex symbol is ugly
    text = strrep(text,'�', '\texteuro '); %uglier than \EURdig
    text = strrep(text, '�', '\ss '); %just in case German is used
    %mathmode
    text = strrep(text, '�', '$\cdot$'); %must be after the $ change
    %special vowels
    text = strrep(text,'�', '\''a'); text = strrep(text,'�', '\`a'); text = strrep(text,'�', '\"a'); text = strrep(text,'�', '\^a'); text = strrep(text,'�', '\~a');
    text = strrep(text,'�', '\''e'); text = strrep(text,'�', '\`e'); text = strrep(text,'�', '\"e'); text = strrep(text,'�', '\^e');
    text = strrep(text,'�', '\''i'); text = strrep(text,'�', '\`i'); text = strrep(text,'�', '\"i'); text = strrep(text,'�', '\^i');
    text = strrep(text,'�', '\''o'); text = strrep(text,'�', '\`o'); text = strrep(text,'�', '\"o'); text = strrep(text,'�', '\^o'); text = strrep(text,'�', '\~o');
    text = strrep(text,'�', '\''u'); text = strrep(text,'�', '\`u'); text = strrep(text,'�', '\"u'); text = strrep(text,'�', '\^u');
    text = strrep(text,'�', '\''A'); text = strrep(text,'�', '\`A'); text = strrep(text,'�', '\"A'); text = strrep(text,'�', '\^A'); text = strrep(text,'�', '\~A');
    text = strrep(text,'�', '\''E'); text = strrep(text,'�', '\`E'); text = strrep(text,'�', '\"E'); text = strrep(text,'�', '\^E');
    text = strrep(text,'�', '\''I'); text = strrep(text,'�', '\`I'); text = strrep(text,'�', '\"I'); text = strrep(text,'�', '\^I');
    text = strrep(text,'�', '\''O'); text = strrep(text,'�', '\`O'); text = strrep(text,'�', '\"O'); text = strrep(text,'�', '\^O'); text = strrep(text,'�', '\~O');
    text = strrep(text,'�', '\''U'); text = strrep(text,'�', '\`U'); text = strrep(text,'�', '\"U'); text = strrep(text,'�', '\^U');
    %other symbols
    text = strrep(text,'�', '\~n');          %lower
    text = strrep(text, char(209), '\~N');   %upper
    text = strrep(text,'�', '\c{c}');        %lower
    text = strrep(text, char(199), '\c{C}'); %upper
    %superscript for ordinal numbers
    if strcmp(args.language, 'en') %only english
        for sup = {'th', 'st', 'nd', 'rd'}
            tmp = regexp(text, strcat('[0-9]', sup{1}, '( |,|\.|:|;|\?|!|$)'), 'match'); %number followed by sup and then space or several symbols or end of string
            for i=1:length(tmp)
                text = strrep(text, tmp{i}, strrep(tmp{i}, sup{1}, strcat('\textsuperscript{', sup{1}, '}')));
            end
        end
    end
end

function terminateProg(script, varargin)
    %
	% terminate program showing an appropriate error
    %
    fprintf(horzcat('\nError in ', script, '\n\n'))
    for i = 1:length(varargin)
        if iscell(varargin{i})
            for j = 1:length(varargin{i})
                if strcmp(varargin{i}{j}, 'DUMMY'); continue; end % skip DUMMY card for user information
                fprintf('  - %s\n', varargin{i}{j})
            end
        else
            fprintf('%s\n', varargin{i})
        end
        fprintf('\n')
    end
    error('Program is terminated!')
end