%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                     %
%     writeLatexCV  02/12/2019                                        %
%                                                                     %
% File name:        libLatexCV.m                                      %
% File type:        Library                                           %
% File description: Library needed by writeLatexCV                    %
% File version:     1.1.0                                             %
%                                                                     %
% Author: Carles Mesado                                               %
% E-mail: mesado31@gmail.com                                          %
%                                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function libLatexCV
    %
    % interface function
    %
    %global functions
    global texFormat
    %interface
    assignin('caller', 'getInputArguments',       @getInputArguments);
    assignin('caller', 'readInputFile',           @readInputFile);
    assignin('caller', 'writeDocumentDefinition', @writeDocumentDefinition);
    assignin('caller', 'writePreamble',           @writePreamble);
    assignin('caller', 'writePageTitle',          @writePageTitle);
    assignin('caller', 'writeTableGeneral',       @writeTableGeneral);
    assignin('caller', 'writeTableResearch',      @writeTableResearch);
    assignin('caller', 'writeTableTeaching',      @writeTableTeaching);
    assignin('caller', 'writeTableExperience',    @writeTableExperience);
    assignin('caller', 'writeTableOther',         @writeTableOther);
    assignin('caller', 'loadLanguage',            @loadLanguage);	
    assignin('caller', 'runPdfLatex',             @runPdfLatex);
    assignin('caller', 'cleanTrash',              @cleanTrash);
    assignin('caller', 'openFile',                @openFile);
    assignin('caller', 'terminateProg',           @terminateProg);
    %get function handler according to OS
    if ispc
        texFormat = @texFormat_win1252;
    else
        texFormat = @texFormat_utf8;
    end
end 

function args = getInputArguments(varArg)
    %
    % process user options
    %
    %file extensions
    args.inputExt  = '.inp';
    args.outputExt = '.pdf';
    args.debugExt  = '.dbg';
    args.latexExt  = '.tex';
    %set default paths
    args.inputPath  = '.'; 
    args.outputPath = '.';
    %set default arguments
    maxArg = 8;
    args.inputName  = 'writeLatexCV';                        %input file name
    args.outputName = 'writeLatexCV';                        %output pdf file name
    args.language = 'en';                                    %language 'CA'/'ES'/'EN'
    args.currency = 'eur';                                   %currency symbol 'USD'/'EUR'/'GBP'/'JPY'
    args.fontSize = 11;                                      %font size, integer
    args.blueLinks = false;                                  %links are blue if true
    args.usDate = false;                                     %US date format in title page if true
    args.usPaper = false;                                    %US paper size if true
    args.allowedPts = [8, 9, 10, 11, 12, 14, 17, 20];        %allowed font sizes with extsizes package
    %check number of input arguments
    if length(varArg) > maxArg
        terminateProg('libLatexCV::getInputArguments::tooManyArguments', horzcat('Up to ', num2str(maxArg), ' input arguments are allowed,  but ', num2str(length(varArg)), ' were given'))
    end
    if ~isempty(varArg)
        %check input mode
        if isempty(strfind(varArg{1}, '='))
            mode = 'standard';
        else
            mode = 'keyword'; % such as 'parameter = value'
        end
        %process input arguments according to the mode
        for i = 1:length(varArg)
            if strcmp(mode, 'standard')
                varArg{i}=strtrim(strrep(mat2str(varArg{i}), '''', '')); %anything to string (including boolean), remove single quotes and trim
                if isempty(varArg{i})
                    terminateProg('libLatexCV::getInputArguments::argumentBadDefined', horzcat('Input argument ', num2str(i), ' is empty,  that is not allowed'), 'Type ''help writeLatexCV.m'' for more information')
                end
                switch i
                    case 1
                        parameter = 'input';
                        value = varArg{i};
                    case 2
                        parameter = 'output';
                        value = varArg{i};
                    case 3
                        parameter = 'language';
                        value = varArg{i};
                    case 4
                        parameter = 'currency';
                        value = varArg{i};
                    case 5
                        parameter = 'font_size';
                        value = varArg{i};
                    case 6
                        parameter = 'blue_links';
                        value = varArg{i};
                    case 7
                        parameter = 'us_date';
						value = varArg{i};
                    case 8
                        parameter = 'us_paper';
						value = varArg{i};
                end
            else
                if isempty(strfind(varArg{i}, '='))
                    terminateProg('libLatexCV::getInputArguments::argumentBadDefined', horzcat('Input argument ', num2str(i), ' (', varArg{i}, ') bad defined, symbol ''='' was expected'), 'If first input argument is defined following the ''keyword'' syntax (''parameter = value''), then all arguments must follow this syntax', 'Type ''help writeLatexCV.m'' for more information')
                end
                parameter = strtrim(varArg{i}(1:strfind(varArg{i}, '=')-1));
                value = strtrim(varArg{i}(strfind(varArg{i}, '=')+1:end));
                if isempty(parameter) || isempty(value)
                    terminateProg('libLatexCV::getInputArguments::argumentBadDefined', horzcat('Input argument ', num2str(i), ' (', varArg{i}, ') bad defined, either the parameter, its value or both are empty'), 'Type ''help writeLatexCV.m'' for more information')
                end
            end
            switch lower(parameter)
                case 'input'
                    [args.inputPath, args.inputName, args.inputExt] = fileparts(value);
                case 'output'
                    [args.outputPath, args.outputName, args.outputExt] = fileparts(value);
                case 'language'
                    args.language = lower(value);
                    if ~strcmp(args.language, 'ca') && ~strcmp(args.language, 'en') && ~strcmp(args.language, 'es')
                        langOpt{1}='''EN'' for English (default)';
                        langOpt{2}='''CA'' for Catalan';
                        langOpt{3}='''ES'' for Spanish';
                        terminateProg('libLatexCV::getInputArguments::languageNotRecognized', horzcat('Language option ''', args.language, ''' is not recognized, only the following options are accepted:'), langOpt)
                    end
                case 'currency'
                    args.currency = lower(value);
                    if ~strcmp(args.currency, 'eur') && ~strcmp(args.currency, 'usd') && ~strcmp(args.currency, 'gbp') && ~strcmp(args.currency, 'jpy')
                        curOpt{1}='''EUR'' for euros (€, defualt)';
                        curOpt{2}='''USD'' for dollars ($)';
                        curOpt{3}='''GBP'' for pounds (£)';
                        curOpt{4}='''JPY'' for yens (¥)';
                        terminateProg('libLatexCV::getInputArguments::currencyNotRecognized', horzcat('Option ''', value, ''' for input argument ''', parameter, ''' is not recognized, only the following options are accepted:'), curOpt)
                    end
                case 'font_size'
                    args.fontSize = str2num(value);
                    if isempty(args.fontSize)
                        terminateProg('libLatexCV::getInputArguments::fontSizeNotRecognized', horzcat('Option ''', value, ''' for input argument ''', parameter, ''' is not recognized, only numeric values are accepted'))
                    end
                    if ~any(args.allowedPts == args.fontSize)
						[~, idx] = min(abs(args.allowedPts-args.fontSize));
						args.fontSize = args.allowedPts(idx);
                        fprintf('Warning: Only these font sizes are allowed 8, 9, 10, 11, 12, 14, 17 and 20, ''%ipt'' will be used instead\n', args.fontSize)
                    end
                case 'blue_links'
                    value = lower(value);
                    if ~strcmp(value, 'true') && ~strcmp(value, 'false')
                        forOpt{1}='false, links are black, just as other text (default)';
                        forOpt{2}='true, links are blue, thus standing out from other text';
                        terminateProg('libLatexCV::getInputArguments::blueLinksNotRecognized', horzcat('Option ''', value, ''' for input argument ''', parameter, ''' is not boolean, only the following options are accepted:'),forOpt)
                    end
                    args.blueLinks = eval(value);
                case 'us_date'
                    value = lower(value);
                    if ~strcmp(value, 'true') && ~strcmp(value, 'false')
                        forOpt{1}='false, European date format, for example 24th of May, 2010 (default)';
                        forOpt{2}='true, American date format, for example May 24th, 2010';
                        terminateProg('libLatexCV::getInputArguments::usDateNotRecognized', horzcat('Option ''', value, ''' for input argument ''', parameter, ''' is not boolean, only the following options are accepted:'),forOpt)
                    end
                    args.usDate = eval(value);
                case 'us_paper'
                    value = lower(value);
                    if ~strcmp(value, 'true') && ~strcmp(value, 'false')
                        forOpt{1}='false, A4 paper size is used (default)';
                        forOpt{2}='true, letter paper size is used';
                        terminateProg('libLatexCV::getInputArguments::usPaperNotRecognized', horzcat('Option ''', value, ''' for input argument ''', parameter, ''' is not boolean, only the following options are accepted:'),forOpt)
                    end
                    args.usPaper = eval(value);
                otherwise
                    argOpt{1}='''input'' for input file name';
                    argOpt{2}='''output'' for output file name';
                    argOpt{3}='''language'' for language option';
                    argOpt{4}='''currency'' for currency option';
                    argOpt{5}='''font_size'' for font size';
                    argOpt{6}='''blue_links'' for blue links';
                    argOpt{7}='''us_date'' for date format in front page';
                    argOpt{8}='''us_paper'' for paper size';
                    terminateProg('libLatexCV::getInputArguments::argumentNotRecognized', horzcat('Input argument ''', parameter, ''' is not recognized, only the following options are accepted:'), argOpt, 'Type ''help writeLatexCV.m'' for more information')
            end
        end
        if args.usDate && (strcmp(args.language, 'ca') || strcmp(args.language, 'es'))
			fprintf('Warning: American date format is not allowed for language option ''%s'', European date format will be used instead\n', args.language)
			args.usDate = false;
		end
    end
	%default files
	if isempty(args.inputPath);  args.inputPath =  '.'; end
	if isempty(args.outputPath); args.outputPath = '.'; end
    args.inputFile  = fullfile(args.inputPath,  strcat(args.inputName,  args.inputExt));
    args.outputFile = fullfile(args.outputPath, strcat(args.outputName, args.outputExt));
    args.debugFile  = fullfile(args.inputPath,  strcat(args.inputName,  args.debugExt));
    args.latexFile  = fullfile(args.outputPath, strcat(args.outputName, args.latexExt));
	if ~fileattrib(args.inputFile)
		terminateProg('libLatexCV::getInputArguments::fileNotFound', horzcat('Input file not found ''', args.inputFile, ''''))
	end
end

function cv = readInputFile(args)
    %
    %read input file created by user
    %
	%pre-process input file
    preProcessInputFile(args.inputFile);
    %initialize some variables
    card  			= 'DUMMY'; %dummy card
    isPersonalCard 	= 0;
	help			= loadHelp();
    %open file
    fdbg = openFile(args.debugFile, 'r');
    while ~feof(fdbg)
        line = fgetl(fdbg);
		if strcmp(line, '+')                              %next item symbol found
			item = item + 1;
		elseif ~isempty(regexp(line, '^#[A-z]', 'once'))  %next card symbol found, symbol # at the beginning of string
			item = 1;
			card = readCard(line);
		else
			terminateProg('libLatexCV::readInputFile::syntaxError', 'Either a new item or a new card was expected, instead this line was found:', line)
		end
        switch card
            case 'BACKGROUNDS'
                cv.general.backgrounds(item)                    = readOneBackground(fdbg);
				checkItem(card, item, cv.general.backgrounds(item), help.general.backgrounds);
            case 'BOOKS'
                cv.research.publications.books(item)            = readOneBook(fdbg);
				checkItem(card, item, cv.research.publications.books(item), help.research.publications.books);
            case 'CODES'
                cv.research.codes(item)                         = readOneCode(fdbg);
				checkItem(card, item, cv.research.codes(item), help.research.codes);
            case 'COLLABORATIONS'
                cv.research.collaborations(item)                = readOneCollaboration(fdbg);
				checkItem(card, item, cv.research.collaborations(item), help.research.collaborations);
            case 'COMPANY'
                cv.general.company                              = readCardCompany(fdbg);
				checkItem(card, item, cv.general.company, help.general.company);
            case 'GIVEN_COURSES'
                cv.teaching.giv_courses(item)                   = readOneCourse(fdbg);
				checkItem(card, item, cv.teaching.giv_courses(item), help.teaching.giv_courses);
            case 'GIVEN_SEMINARS'
                cv.teaching.giv_seminars(item)                  = readOneCourse(fdbg);
				checkItem(card, item, cv.teaching.giv_seminars(item), help.teaching.giv_seminars);
            case 'GIVEN_WORKSHOPS'
                cv.teaching.giv_workshops(item)                 = readOneCourse(fdbg);
				checkItem(card, item, cv.teaching.giv_workshops(item), help.teaching.giv_workshops);
            case 'INTERNATIONAL_CONFERENCES'
                cv.research.publications.int_conferences(item)  = readOneConference(fdbg);
				checkItem(card, item, cv.research.publications.int_conferences(item), help.research.publications.int_conferences);
            case 'INTERNSHIPS'
                cv.research.internships(item)                   = readOneInternship(fdbg);
				checkItem(card, item, cv.research.internships(item), help.research.internships);
            case 'JOBS'
                cv.experience(item)                             = readOneExperience(fdbg);
				checkItem(card, item, cv.experience(item), help.experience);
            case 'LANGUAGES'
                cv.other.languages.languages(item)              = readOneLanguage(fdbg);
				checkItem(card, item, cv.other.languages.languages(item), help.other.languages.languages);
            case 'LANGUAGE_TITLES'
                cv.other.languages.lan_titles(item)             = readOneLanTitle(fdbg);
				checkItem(card, item, cv.other.languages.lan_titles(item), help.other.languages.lan_titles);
            case 'LANGUAGE_COURSES'
                cv.other.courses.lan_courses(item)              = readOneLanCourse(fdbg);
				checkItem(card, item, cv.other.courses.lan_courses(item), help.other.courses.lan_courses);
            case 'MATERIALS'
                cv.teaching.materials(item)                     = readOneMaterial(fdbg);
				checkItem(card, item, cv.teaching.materials(item), help.teaching.materials);
            case 'NATIONAL_CONFERENCES'
                cv.research.publications.nat_conferences(item)  = readOneConference(fdbg);
				checkItem(card, item, cv.research.publications.nat_conferences(item), help.research.publications.nat_conferences);
            case 'PAPERS'
                cv.research.publications.papers(item)           = readOnePaper(fdbg);
				checkItem(card, item, cv.research.publications.papers(item), help.research.publications.papers);
            case 'PATENTS'
                cv.research.patents(item)           			= readOnePatent(fdbg);
				checkItem(card, item, cv.research.patents(item), help.research.patents);
            case 'PERSONAL'
                isPersonalCard                                  = 1;
                cv.general.personal                             = readCardPersonal(fdbg);
				checkItem(card, item, cv.general.personal, help.general.personal);
            case 'PROJECTS'
                cv.research.projects(item)                      = readOneProject(fdbg);
				checkItem(card, item, cv.research.projects(item), help.research.projects);
            case 'RECEIVED_COURSES'
                cv.other.courses.tec_courses(item)              = readOneCourse(fdbg);
				checkItem(card, item, cv.other.courses.tec_courses(item), help.other.courses.tec_courses);
            case 'RECEIVED_SEMINARS'
                cv.other.courses.tec_seminars(item)             = readOneCourse(fdbg);
				checkItem(card, item, cv.other.courses.tec_seminars(item), help.other.courses.tec_seminars);
            case 'RECEIVED_WORKSHOPS'
                cv.other.courses.tec_workshops(item)            = readOneCourse(fdbg);
				checkItem(card, item, cv.other.courses.tec_workshops(item), help.other.courses.tec_workshops);
            case 'SCHOLARSHIPS'
                cv.research.scholarships(item)                  = readOneScholarship(fdbg);
				checkItem(card, item, cv.research.scholarships(item), help.research.scholarships);
            case 'ALIASES'
                %nothing is done here
            case 'GENERAL_APPS'
                cv.other.computer.sof_generals(item)            = readOneSoftware(fdbg);
				checkItem(card, item, cv.other.computer.sof_generals(item), help.other.computer.sof_generals);
            case 'DEVELOPER_APPS'
                cv.other.computer.sof_developers(item)          = readOneSoftware(fdbg);
				checkItem(card, item, cv.other.computer.sof_developers(item), help.other.computer.sof_developers);
            case 'SPECIFIC_APPS'
                cv.other.computer.sof_specifics(item)           = readOneSpecificSoftware(fdbg);
				checkItem(card, item, cv.other.computer.sof_specifics(item), help.other.computer.sof_specifics);
			case 'COURSES'
                cv.teaching.subjects(item)                      = readOneSubject(fdbg);
				checkItem(card, item, cv.teaching.subjects(item), help.teaching.subjects);
        end
    end
    fclose(fdbg);
    if ~isPersonalCard
        terminateProg('libLatexCV::readInputFile::personalCardNotFound', 'Mandatory PERSONAL card was not found')
    end
	function c = readCard(line)
		% obtain card name
		cards = {'ALIASES', 'BACKGROUNDS', 'BOOKS', 'CODES', 'COLLABORATIONS', 'COMPANY', 'COURSES', 'DEVELOPER_APPS', 'DUMMY', 'GENERAL_APPS', 'GIVEN_COURSES', 'GIVEN_SEMINARS', 'GIVEN_WORKSHOPS', 'INTERNATIONAL_CONFERENCES', 'INTERNSHIPS', 'JOBS', 'LANGUAGE_COURSES', 'LANGUAGE_TITLES', 'LANGUAGES', 'MATERIALS', 'NATIONAL_CONFERENCES', 'PAPERS', 'PATENTS', 'PERSONAL', 'PROJECTS', 'RECEIVED_COURSES', 'RECEIVED_SEMINARS', 'RECEIVED_WORKSHOPS', 'SCHOLARSHIPS', 'SPECIFIC_APPS'};
		for i = 1:length(cards)
			if strcmpi(line, strcat('#', cards{i})) %find card name, case insensitive
				c = cards{i};
				break
			end
			%terminate if card name does not match any available cards
			if i == length(cards)
				terminateProg('libLatexCV::readInputFile::readCard::cardNotRecognized', horzcat('Card not recognized in line ', line), 'Available cards are:', cards)
			end
		end
    end
    function alias = getAliases(fname)
		% read aliases introduced by the user
        alias = []; s = 0; isAliasCard = 0;
        %open file
        finp = openFile(fname, 'r');
        while ~feof(finp)
            line = fgetl(finp);
            %remove comments
			tmp  = strfind(line, '%');
            if ~isempty(tmp)
                line(tmp(1):end) = []; 
            end
			%trim line
			line = strtrim(line);
            %skip ampty lines
            if isempty(line)
                continue
            end
            %find ALIASES card
            if ~isempty(strfind(upper(line), '#ALIASES'))   %start of ALIASES card
				isAliasCard = 1;
                continue
            end
            if isAliasCard 
                if ~isempty(regexp(line, '^#[A-z]', 'once')) %next card, end of ALIASES card
                    break
                else
                    if ~isempty(strfind(line, '$')) && length(strfind(line, '$')) == 1 && ...
                       ~isempty(strfind(line, '=')) && length(strfind(line, '=')) == 1 %if one alias per line is found
                        s = s+1;
                        alias(s).short = strtrim(line(strfind(line, '$')+1:strfind(line, '=')-1));
                        alias(s).value = strtrim(line(strfind(line, '=')+1:end));
                        if isempty(alias(s).short) || isempty(alias(s).value)
                            terminateProg('libLatexCV::readInputFile::getAliases::aliasBadDefined', 'Aliases bad defined in line:', line)
                        end
                        if length(alias(s).short) ~= length(regexp(alias(s).short, '[0-9A-z_]')) %alphanumeric character or underscore
                            terminateProg('libLatexCV::readInputFile::getAliases::aliasBadDefined', 'Aliases bad defined in line:', line, 'Alias names only accept alphanumeric characters and underscore, that is [0-9A-z_]')
                        end
                    else
                        terminateProg('libLatexCV::readInputFile::getAliases::aliasBadDefined', 'Aliases bad defined in line:', line, 'Only one alias per line is allowed and characters ''$'' and ''='' are not allowed in the alias name or definition')
                    end
                end
            end
        end
        fclose(finp);
    end
    function preProcessInputFile(fname)
		% pre-process input file to be read by main program
        alias     = getAliases(fname);       %obtain aliases
        %open some files
        finp = openFile(fname, 'r');			 %file id for original file
        fdbg = openFile(args.debugFile, 'w');	 %file id for processed file   
        isAliasCard = 0; 						 %flag to find aliases card
        while ~feof(finp)
            line = fgetl(finp);
			%remove comments
			tmp  = strfind(line, '%');
            if ~isempty(tmp)
                line(tmp(1):end) = []; 
            end
			%trim line
			line = strtrim(line);
			%remove empty lines
			if isempty(line)
				continue
            end
            %replace '###' (empty info) by empty line
			if strcmp(line, '###')
				line='';
			end
            %remove ALIASES card
            if ~isempty(strfind(upper(line), '#ALIASES'))   %start of ALIASES card
				isAliasCard = 1;
                continue
            end
            if isAliasCard 
                if ~isempty(regexp(line, '^#[A-z]', 'once')) %next card, end of ALIASES card
                    isAliasCard = 0;
                else
                    continue
                end
            end
            %replace aliases
            tmp=regexp(line, '\$[0-9A-z_]+', 'match'); %dollar symbol followed by alphanumeric character or underscore repeted as menay times as needed
            for i = 1:length(tmp)
                for s = 1:length(alias)
                    if strcmp(tmp{i}, strcat('$', alias(s).short))
                        line = strrep(line, tmp{i}, alias(s).value);    %replace alias
                        break
                    end
                end
            end
            %check if some alias was undefined
            tmp=regexp(line, '\$[0-9A-z_]+', 'match');    
            for i = 1:length(tmp)
                terminateProg('libLatexCV::readInputFile::preProcessInputFile::aliasNotDefined', strcat('Alias ''', tmp{i}, ''' was not defined, see the following line:'), line)
            end
			%write line in processed file
            fprintf(fdbg, '%s\n', line);
        end
        fprintf(fdbg, '%s\n', '#DUMMY'); %add dammy card, so a syntax error con be handled properly, if any, in last item of last card
        fclose(fdbg); %close both files
        fclose(finp);
    end
	% the following functions read one item for a specific card
    function dat = readOneBackground(f)
        dat.title       = fgetl(f);
        dat.university  = fgetl(f);
        dat.year        = fgetl(f);
    end
    function dat = readOneBook(f)
        dat.authors     = fgetl(f);
        dat.title       = fgetl(f);
        dat.link        = fgetl(f);
        dat.publisher   = fgetl(f);
        dat.reference   = fgetl(f);
		dat.contribution= fgetl(f);
		dat.pages       = fgetl(f);
        dat.year        = fgetl(f);
    end
    function dat = readOneCode(f)
        dat.short       = fgetl(f);
        dat.long        = fgetl(f);
		dat.description = fgetl(f);
        dat.link        = fgetl(f);
    end
    function dat = readOneCollaboration(f)
        dat.sdate       = fgetl(f);
        dat.edate       = fgetl(f);
        dat.group       = fgetl(f);
        dat.department  = fgetl(f);
        dat.university  = fgetl(f);
    end
    function dat = readCardCompany(f)
        dat.name        = fgetl(f);
        dat.address     = fgetl(f);
        dat.department  = fgetl(f);
        dat.job         = fgetl(f);
        dat.telephone   = fgetl(f);
        dat.email       = fgetl(f);
    end
    function dat = readOneExperience(f)
        dat.sdate       = fgetl(f);
        dat.edate       = fgetl(f);
        dat.company     = fgetl(f);
        dat.description = fgetl(f);
    end
    function dat = readOneCourse(f)
        dat.title       = fgetl(f);
        dat.entity      = fgetl(f);
        dat.duration    = fgetl(f);
        dat.year        = fgetl(f);
    end
	function dat = readOneConference(f)
        dat.authors     = fgetl(f);
        dat.title       = fgetl(f);
        dat.conference  = fgetl(f);
        dat.link        = fgetl(f);
        dat.location    = fgetl(f);
        dat.reference   = fgetl(f);
		dat.contribution= fgetl(f);
		dat.pages	    = fgetl(f);
        dat.date        = fgetl(f);
    end
    function dat = readOneInternship(f)
        dat.sdate       = fgetl(f);
        dat.edate       = fgetl(f);
        dat.university  = fgetl(f);
        dat.location    = fgetl(f);
        dat.description = fgetl(f);
		dat.advisor     = fgetl(f);
    end
    function dat = readOneLanguage(f)
        dat.language    = fgetl(f);
        dat.listening   = fgetl(f);
        dat.speaking    = fgetl(f);
        dat.writing     = fgetl(f);
    end
    function dat = readOneLanCourse(f)
        dat.title       = fgetl(f);
        dat.entity      = fgetl(f);
        dat.location    = fgetl(f);
        dat.year        = fgetl(f);
    end
    function dat = readOneLanTitle(f)
        dat.title       = fgetl(f);
        dat.entity      = fgetl(f);
        dat.year        = fgetl(f);
    end
	function dat = readOneMaterial(f)
        dat.title       = fgetl(f);
        dat.publisher   = fgetl(f);
        dat.reference   = fgetl(f);
        dat.year        = fgetl(f);
    end
	function dat = readOnePaper(f)
        dat.authors     = fgetl(f);
        dat.title       = fgetl(f);
        dat.link        = fgetl(f);
        dat.journal     = fgetl(f);
        dat.publisher   = fgetl(f);
        dat.reference   = fgetl(f);
		dat.contribution= fgetl(f);
        dat.volume      = fgetl(f);
        dat.pages       = fgetl(f);
        dat.year        = fgetl(f);
    end
	function dat = readOnePatent(f)
        dat.authors     = fgetl(f);
        dat.title       = fgetl(f);
        dat.description = fgetl(f);
        dat.number      = fgetl(f);
		dat.date        = fgetl(f);
		dat.type        = fgetl(f);
    end
	function dat = readCardPersonal(f)
        dat.surname     = fgetl(f);
        dat.name        = fgetl(f);
        dat.id          = fgetl(f);
        dat.birth       = fgetl(f);
        dat.telephone   = fgetl(f);
        dat.address     = fgetl(f);
        dat.city        = fgetl(f);
        dat.code        = fgetl(f);
    end
	function dat = readOneProject(f)
        dat.title       = fgetl(f);
        dat.entity      = fgetl(f);
        dat.leader      = fgetl(f);
        dat.sdate       = fgetl(f);
        dat.edate       = fgetl(f);
        dat.amount      = fgetl(f);
        dat.people      = fgetl(f);
    end
    function dat = readOneScholarship(f)
        dat.title       = fgetl(f);
        dat.description = fgetl(f);
        dat.amount      = fgetl(f);
        dat.duration    = fgetl(f);
		dat.location    = fgetl(f);
		dat.year        = fgetl(f);
    end
	function dat = readOneSoftware(f)
        dat.software    = fgetl(f);
    end
    function dat = readOneSpecificSoftware(f)
		dat.software    = fgetl(f);
		dat.description = fgetl(f);
    end
	function dat = readOneSubject(f)
		dat.subject     = fgetl(f);
		dat.department  = fgetl(f);
		dat.university  = fgetl(f);
		dat.plan	    = fgetl(f);
		dat.type        = fgetl(f);
		dat.grade       = fgetl(f);
		dat.hours       = fgetl(f);
    end
    function checkItem(c, i, d, h)
		% check if there is a syntax error in item, if so, show a nice table with item info and terminate with error
		badField = [];
		fields = fieldnames(d); % each field of d structure is allocated into fields cell
		for idx=1:length(fields)
			if strcmp(d.(fields{idx}), '+') ||...                     % if the whole field is '+'
              ~isempty(regexp(d.(fields{idx}), '^#[A-z]', 'once'))    % or it is a card name, case insensitive
                badField = fields{idx};
                break
			end
		end
		if ~isempty(badField)
			fprintf(' +------------------------+--------------------------------------------------------------+------------------------------------------------------------------------+\n')
			fprintf(' |                        |                                                              |                                                                        |\n')
			fprintf(' | Parameter              | User input                                                   | Description                                                            |\n')
			fprintf(' +------------------------+--------------------------------------------------------------+------------------------------------------------------------------------+\n')
            fprintf(' |                        |                                                              |                                                                        |\n')
			for idx=1:length(fields)
                if ( isnumeric(d.(fields{idx})) && d.(fields{idx}) == -1 ) ||...
                        strcmp(d.(fields{idx}), '#DUMMY') %this happens when eof is reached 
                    d.(fields{idx})='';
                end
				if length(d.(fields{idx}))>60
					fprintf(' | %2i. %-18s | %-57s... | %-70s |\n', idx, fields{idx}, d.(fields{idx})(1:57), h.(fields{idx}))
				else
					fprintf(' | %2i. %-18s | %-60s | %-70s |\n', idx, fields{idx}, d.(fields{idx}), h.(fields{idx}))
				end
			end
			fprintf(' |                        |                                                              |                                                                        |\n')
			fprintf(' +------------------------+--------------------------------------------------------------+------------------------------------------------------------------------+\n\n')
			terminateProg('libLatexCV::readInputFile::checkItem::syntaxError', horzcat('A syntax error is found in item ', num2str(i), ' of card ', c), 'See table above')
		end
	end
	function help = loadHelp()
		% load help strings to help user when syntax error is found
		help.general.backgrounds.title 							= 'Academic title';
		help.general.backgrounds.university						= 'University who issues the title';
		help.general.backgrounds.year							= 'Year of issue';
		help.research.publications.books.authors 		 		= 'List of authors separated by commas (do not use ''and'' between last items)';
		help.research.publications.books.title					= 'Title of book';
		help.research.publications.books.link					= 'Publication link';
		help.research.publications.books.publisher 				= 'Publisher or editor';
		help.research.publications.books.reference				= 'Book reference';
		help.research.publications.books.contribution			= 'Contribution (author, coauthor, editor, coordinator, reviewer...)';
		help.research.publications.books.pages					= 'Number of pages';
		help.research.publications.books.year 					= 'Publishing year';
		help.research.collaborations.sdate						= 'Starting date';
		help.research.collaborations.edate 						= 'Ending date';
		help.research.collaborations.group 						= 'Hosting group';
		help.research.collaborations.department					= 'Department the group belongs to';
		help.research.collaborations.university					= 'University the department belongs to';
        help.research.codes.short       						= 'Code short name (acronym)';
        help.research.codes.long        						= 'Code lone name (expand acronym)';
        help.research.codes.description   						= 'Code brief description';
        help.research.codes.link           						= 'Code link';
		help.general.company.name 								= 'Company name';
		help.general.company.address 							= 'Company address';
		help.general.company.department							= 'Host department';
		help.general.company.job 								= 'Job in department';
		help.general.company.telephone 							= 'Telephone';
		help.general.company.email 								= 'Email';
		help.experience.sdate 									= 'Starting date';
		help.experience.edate									= 'Ending date';
		help.experience.company                 				= 'Company name';
		help.experience.description         					= 'Job description';
		help.teaching.giv_courses.title							= 'Course name';
		help.teaching.giv_courses.entity						= 'Entity where the course is given (school; university; institute... )';
		help.teaching.giv_courses.duration						= 'Course duration in hours';
		help.teaching.giv_courses.year							= 'Year the course is given';
		help.teaching.giv_seminars.title 						= 'Seminar name';
		help.teaching.giv_seminars.entity						= 'Entity where the seminar is given (school; university; institute... )';
		help.teaching.giv_seminars.duration						= 'Seminar duration in hours';
		help.teaching.giv_seminars.year							= 'Year the seminar is given';
		help.teaching.giv_workshops.title 						= 'Workshop name';
		help.teaching.giv_workshops.entity						= 'Entity where the workshop is given (school; university; institute... )';
		help.teaching.giv_workshops.duration					= 'Workshop duration in hours';
		help.teaching.giv_workshops.year						= 'Year the workshop is given';
		help.research.publications.int_conferences.authors		= 'List of authors separated by commas (do not use ''and'' between last items)';
		help.research.publications.int_conferences.title 		= 'Contribution title';
		help.research.publications.int_conferences.conference	= 'Conference name';
        help.research.publications.int_conferences.link     	= 'Conference link';
		help.research.publications.int_conferences.location		= 'Conference place';
		help.research.publications.int_conferences.reference 	= 'Conference reference';
		help.research.publications.int_conferences.contribution	= 'Contribution (presentation, poster, organizer, committee...)';
		help.research.publications.int_conferences.pages		= 'Contribution pages';
		help.research.publications.int_conferences.date			= 'Date of celebration';
		help.research.internships.sdate							= 'Starting date';
		help.research.internships.edate							= 'Ending date';
		help.research.internships.university 					= 'School; university; institute...';
		help.research.internships.location 						= 'Location';
		help.research.internships.description					= 'Description of internship';
		help.research.internships.advisor						= 'Advisor';
		help.other.languages.languages.language					= 'Language';
		help.other.languages.languages.listening				= 'Listening skills (A1, A2, B1, B2, C1 or C2)';
		help.other.languages.languages.speaking 				= 'Speaking skills (A1, A2, B1, B2, C1 or C2)';
		help.other.languages.languages.writing					= 'Writing skills (A1, A2, B1, B2, C1 or C2)';
		help.other.courses.lan_courses.title					= 'Course name';
		help.other.courses.lan_courses.entity					= 'Entity who gives the course (school; university; institute... )';
		help.other.courses.lan_courses.location					= 'Place where the course if given';
		help.other.courses.lan_courses.year						= 'Year the course is given';
		help.other.languages.lan_titles.title 					= 'Language title';
		help.other.languages.lan_titles.entity					= 'Entity who issues the title (school; university; institute... )';
		help.other.languages.lan_titles.year					= 'Year of issue';
		help.teaching.materials.title							= 'Name or title';
		help.teaching.materials.publisher						= 'Publisher or editor';
		help.teaching.materials.reference 						= 'Material reference';
        help.teaching.materials.year    						= 'Year of publication';
		help.research.publications.nat_conferences.authors 		= 'List of authors separated by commas (do not use ''and'' between last items)';
		help.research.publications.nat_conferences.title 		= 'Contribution title';
		help.research.publications.nat_conferences.conference	= 'Conference name';
        help.research.publications.nat_conferences.link     	= 'Conference link';
		help.research.publications.nat_conferences.location		= 'Conference place';
		help.research.publications.nat_conferences.reference 	= 'Conference reference';
		help.research.publications.nat_conferences.contribution	= 'Contribution (presentation, poster, organizer, committee...)';
		help.research.publications.nat_conferences.pages		= 'Contribution pages';
		help.research.publications.nat_conferences.date			= 'Date of celebration';
		help.research.publications.papers.authors				= 'List of authors separated by commas (do not use ''and'' between last items)';
		help.research.publications.papers.title					= 'Paper title';
        help.research.publications.papers.link					= 'Publication link';
		help.research.publications.papers.publisher				= 'Publisher name (or editorial)';
		help.research.publications.papers.journal				= 'Journal name';
		help.research.publications.papers.reference				= 'Paper reference';
		help.research.publications.papers.contribution			= 'Contribution (main author, coauthor, editor, reviewer...)';
		help.research.publications.papers.volume 				= 'Journal volume';
		help.research.publications.papers.pages					= 'Journal pages';
		help.research.publications.papers.year 					= 'Publishing year';
		help.research.patents.authors							= 'List of authors separated by commas (do not use ''and'' between last items)';
		help.research.patents.title								= 'Patent title';
		help.research.patents.description						= 'Patent description';
		help.research.patents.number							= 'Patent number';
		help.research.patents.date								= 'Concession date';
		help.research.patents.type								= 'Patent type (national, European, cooperation treatment...)';
		help.general.personal.surname							= 'Surname of person the CV is being written';
		help.general.personal.name 								= 'Name';
		help.general.personal.id 								= 'Id number';
		help.general.personal.birth								= 'Birth date';
		help.general.personal.telephone							= 'Contact telephone';
		help.general.personal.address							= 'Personal address';
		help.general.personal.city 								= 'City';
		help.general.personal.code 								= 'Postal code';
		help.research.projects.title  							= 'Project title';
		help.research.projects.entity 				 			= 'Entity giving the project';
		help.research.projects.leader							= 'Main researcher';
		help.research.projects.sdate 							= 'Starting date';
		help.research.projects.edate 							= 'Ending date';
		help.research.projects.amount							= 'Amount of money';
		help.research.projects.people							= 'Number of researchers';
		help.other.courses.tec_courses.title					= 'Course name';
		help.other.courses.tec_courses.entity					= 'Entity where the course is given (school; university; institute... )';
		help.other.courses.tec_courses.duration					= 'Course duration in hours';
		help.other.courses.tec_courses.year						= 'Year the course is given';
		help.other.courses.tec_seminars.title					= 'Seminar name';
		help.other.courses.tec_seminars.entity					= 'Entity where the seminar is given (school; university; institute... )';
		help.other.courses.tec_seminars.duration				= 'Seminar duration in hours';
		help.other.courses.tec_seminars.year					= 'Year the seminar is given';
		help.other.courses.tec_workshops.title 					= 'Workshop name';
		help.other.courses.tec_workshops.entity					= 'Entity where the workshop is given (school; university; institute... )';
		help.other.courses.tec_workshops.duration				= 'Workshop duration in hours';
		help.other.courses.tec_workshops.year					= 'Year the workshop is given';
		help.research.scholarships.title 						= 'Name of scholarship';
		help.research.scholarships.description					= 'Description of scholarship';
		help.research.scholarships.amount 						= 'Amount of money';
		help.research.scholarships.duration 					= 'Duration of scholarship in months';
		help.research.scholarships.location 					= 'Location';
		help.research.scholarships.year		 					= 'Year';
		help.other.computer.sof_generals.software 				= 'Software name';
		help.other.computer.sof_developers.software 			= 'Software name';
		help.other.computer.sof_specifics.software				= 'Software name';
		help.other.computer.sof_specifics.description			= 'Software description';
		help.teaching.subjects.subject							= 'Subject name';
		help.teaching.subjects.department						= 'Department';
		help.teaching.subjects.university						= 'University';
		help.teaching.subjects.plan								= 'Subject plan (bachelor''s, master, PhD...)';
		help.teaching.subjects.type								= 'Subject type (core, compulsory, optional, free choice...)';
		help.teaching.subjects.grade							= 'Grade';
		help.teaching.subjects.hours							= 'Teaching hours';
	end
end

function writeDocumentDefinition(fid, args)
	if args.usPaper
		fprintf(fid,'\\documentclass[%ipt, letterpaper]{extarticle}\n\n', args.fontSize);
	else
		fprintf(fid,'\\documentclass[%ipt, a4paper]{extarticle}\n\n', args.fontSize);
	end
end

function writePreamble(fid, lan, cv)
    %
    % write latex preamble
    %
    %load global variables
    global args vmargin hmargin texFormat
    %preamble, load packages, new commands, setup & etc
    fprintf(fid, '%s\n', '%%%%%%%%%%%%');
	fprintf(fid, '%s\n', '% PREAMBLE %');
	fprintf(fid, '%s\n', '%%%%%%%%%%%%');
    fprintf(fid, '\n');
    fprintf(fid, '%s\n', '\usepackage[T1]{fontenc}');                                                             %recommended font encoding
    if ispc
        fprintf(fid, '%s\n', '\usepackage[cp1252]{inputenc}');                                                    %encode option Windows-1252 (western europe)
    else
        fprintf(fid, '%s\n', '\usepackage[utf8]{inputenc}');                                                      %encode option UTF-8
    end
    fprintf(fid, '%s\n', '\usepackage{lmodern}');                                                                 %Latin Modern fonts
    fprintf(fid, '%s\n', '\usepackage{extsizes}');                                                                %extra font sizes
    fprintf(fid, '%s\n', '\usepackage{multicol}');                                                                %play with columns in tables (marge cells)
    fprintf(fid, '%s\n', '\usepackage{multirow}');                                                                %same with rows
    fprintf(fid, '%s\n', '\usepackage{array}');                                                                   %something with new column type
    fprintf(fid, '%s\n', '\usepackage{longtable}');                                                               %table spans multiple pages
    fprintf(fid, '%s\n', '\usepackage{hhline}');                                                                  %fix bug: black lines over colored cells
    fprintf(fid, '%s\n', '\usepackage[english]{babel}');                                                          %language commands
    fprintf(fid, '%s\n', '\usepackage[table]{xcolor}');                                                           %color in tables
    fprintf(fid, '%s\n', '\usepackage{lastpage}');                                                                %to get # of pages
    if ~ispc                                                                                                      %some problems were found with marvosym under windows
        fprintf(fid, '%s\n', '\usepackage{marvosym}');                                                            %to get euro, beta and at symbols
    end
    fprintf(fid, '%s\n', '\usepackage{textcomp}');                                                                %to get yen and dollar symbols
    fprintf(fid, '%s\n', '\usepackage{fancyhdr}');                                                                %to modify default header
    fprintf(fid, '%s%.3f%s%.3f%s\n', '\usepackage[vmargin=', vmargin, 'cm,hmargin=', hmargin, 'cm]{geometry}');   %margins
    fprintf(fid, '%s\n', '\usepackage{hyperref}');                                                                %add links and bookmarks
    fprintf(fid, '%s\n', '\hypersetup{');                                                                         %links and bookmarks setup
    fprintf(fid, '\t%s\n', 'bookmarksopen=true,');                                                                %expand bookmarks
    fprintf(fid, '\t%s\n', 'unicode=true,');                                                                      %non-Latin characters in bookmarks
    fprintf(fid, '\t%s\n', 'pdfstartview={FitH},');                                                               %fits the width of the page to the window
    fprintf(fid, '\t%s%s %s%s\n', 'pdftitle={CV ', texFormat(cv.name), texFormat(cv.surname), '},');              %title
    fprintf(fid, '\t%s\n', 'colorlinks=true,');                                                                   %false: boxed links; true: colored links
    fprintf(fid, '\t%s\n', 'linkcolor=black,');                                                                   %color for internal links
    if args.blueLinks
		fprintf(fid, '\t%s\n', 'urlcolor=blue');                                                                  %color for external links
	else
		fprintf(fid, '\t%s\n', 'urlcolor=black');                                                                 %color for external links
	end
    fprintf(fid, '%s\n', '}');
    fprintf(fid, '%s\n', '\newcolumntype{C}[1]{>{\centering\arraybackslash}m{#1}}');                              %new column type in table (centered justified)
    fprintf(fid, '%s\n', '\newcolumntype{L}[1]{>{\raggedright\arraybackslash}m{#1}}');                            %new column type in table (left justified)
    fprintf(fid, '%s\n', '\newcolumntype{N}{@{}m{0pt}@{}}');                                                      %void column to avoid Vertical alignment in table: m-column, row size - problem in last column
    %fprintf(fid, '%s\n', '\newcommand*{\doi}[1]{DOI: \href{http://dx.doi.org/#1}{#1}}');                         %short command for doi link
    fprintf(fid, '%s\n', '\setlength{\LTpre}{0pt}');                                                              %remove space before longtable
    fprintf(fid, '%s\n', '\setlength{\LTpost}{0pt}');                                                             %remove space after longtable
    fprintf(fid, '%s\n', '\renewcommand{\familydefault}{\sfdefault}');                                            %change default font type to sans-serif
    fprintf(fid, '%s\n', '\parindent 0cm');                                                                       %indentation first paragraph line
    fprintf(fid, '%s\n', '\pagestyle{fancy}');                                                                    %activate fancy header by default
    fprintf(fid, '%s\n', '\fancyhf{}');                                                                           %it's needed, don't know why
    fprintf(fid, '%s\n', '\renewcommand{\headrulewidth}{0pt}');                                                   %remove hline in header
    fprintf(fid, '%s\n', '\rfoot{\thepage}');                                                                     %page number at bottom-right page (#)
    fprintf(fid, '%s\n', '%Uncomment next lines for header and footer customization');
    fprintf(fid, '%s%s %s%s\n', '%\rhead{', texFormat(cv.name), texFormat(cv.surname), '}');                      %add your name in the top-right page
    fprintf(fid, '%s%s%s\n', '%\lhead{', lan.cvtitle, '}');                                                       %add curriculum vitae in the top-left page
    fprintf(fid, '%s%s%s\n', '%\rfoot{', lan.page, ' \thepage}');                                      %page number at bottom-right page (Page #)
    fprintf(fid, '\n');
end

function writePageTitle(fid,lan,cv)
    %
    % write page title in latex
    %
    % load global variables
    global sectRowHeight texFormat
    % write title page
%     fprintf(fid, '\t\\frontmatter\n');
%     fprintf(fid, '\n');
    fprintf(fid, '\t\\pdfbookmark[0]{%s}{cv:title}\\label{cv:title}\n', lan.cvtitle);
    fprintf(fid, '\t\\begin{titlepage}\n');
    fprintf(fid, '\t\t\\thispagestyle{empty}\n');
    fprintf(fid, '\t\t\\vspace*{%.2f\\textheight}\n', 0.1);
    fprintf(fid, '\t\t{\\textbf{\\Huge %s}\\par}\n', lan.cvtitle);
    fprintf(fid, '\t\t\\vspace{%.2f\\textheight}\n', 0.1);
    fprintf(fid, '\t\t\\begin{tabular}{L{0.1\\linewidth}L{0.9\\linewidth}N}\n');
    fprintf(fid, '\t\t\t{\\Large %10s:} & {\\Large %-20s %-20s} & \\\\[%.2fcm]\n', lan.name, texFormat(cv.name), texFormat(cv.surname), sectRowHeight);
    fprintf(fid, '\t\t\t{\\Large %10s:} & {\\Large %-41s} & \\\\[%.2fcm]\n', lan.date, lan.frontDate, sectRowHeight);
    fprintf(fid, '\t\t\t{\\Large %10s:} & {\\Large \\pageref{LastPage} %22s} & \\\\[%.2fcm]\n', lan.pages, '', sectRowHeight);
    fprintf(fid, '\t\t\\end{tabular}\n');
    fprintf(fid, '\t\t\\par\n');
    fprintf(fid, '\t\t\\vspace*{\\fill}\n');
    fprintf(fid, '\t\t%s\n', lan.disclaimer);
    fprintf(fid, '\t\\end{titlepage}\n');
	fprintf(fid, '\t\\cleardoublepage\n');
    fprintf(fid, '\n');
%     fprintf(fid, '\t\\mainmatter\n');
%     fprintf(fid, '\n');
end

function writeTableGeneral(fid, lan, tab, ntab)
    %
    % write table with general info   
    %
    % load global variables
    global smallRowHeight stdRowHeight colWidthMult1N colWidthPlus1N colWidthMult2N colWidthPlus2N colWidthMult3N colWidthPlus3N texFormat
	% local variables
	nsec = 0;
    % write table header
    writeTableHeader(fid, lan.header.general, ntab)
    % write sections
    if isfield(tab, 'personal')
		nsec = nsec + 1;
        writeSectPersonal(fid, lan, tab.personal, ntab, nsec);
    end
    if isfield(tab, 'company')
		nsec = nsec + 1;
        writeSectCompany(fid, lan, tab.company, ntab, nsec);
    end
    if isfield(tab, 'backgrounds')
		nsec = nsec + 1;
        writeSectBackgrounds(fid, lan, tab.backgrounds, ntab, nsec);
    end
    fprintf(fid, '\t\\newpage\n\n');
    % function definition for sections
	function writeSectPersonal(fid, lan, tab, ntab, nsec)
        % write section header
        writeTableSectHeader(fid, lan.header.personal, ntab, nsec)
        % write table section
        fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}L{%.3f\\linewidth}N}\n', colWidthMult2N+colWidthPlus2N, colWidthMult2N+colWidthPlus2N);
		% set a very narrow first row
		fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
		fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.surname,     ':} ', texFormat(tab.surname)),...
                horzcat('\textbf{', lan.id,          ':} ', texFormat(tab.id)),           stdRowHeight);
		fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.name,        ':} ', texFormat(tab.name)),...
				horzcat('\textbf{', lan.birth,       ':} ', texFormat(tab.birth)),        stdRowHeight);
		fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.address,     ':} ', texFormat(tab.address)),...
				horzcat('\textbf{', lan.telephone,   ':} ', texFormat(tab.telephone)),    stdRowHeight);
		fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.city,        ':} ', texFormat(tab.city)),...
				horzcat('\textbf{', lan.code,        ':} ', texFormat(tab.code)),         stdRowHeight);
		% set a very narrow last row
		fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm] \\hline\n', '', '', smallRowHeight);
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
    function writeSectCompany(fid, lan, tab, ntab, nsec)
        % write section header
        writeTableSectHeader(fid, lan.header.company, ntab, nsec)
        % write table section
        fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}N}\n', colWidthMult1N+colWidthPlus1N);
		% set a very narrow first row
		fprintf(fid, '\t\t%300s & \\\\[%.2fcm]\n', '', smallRowHeight);
		fprintf(fid, '\t\t%-300s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.employer,     ':} ', texFormat(tab.name)),       stdRowHeight);
		fprintf(fid, '\t\t%-300s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.address,      ':} ', texFormat(tab.address)),	stdRowHeight);
		fprintf(fid, '\t\t%-300s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.department,   ':} ', texFormat(tab.department)),	stdRowHeight);
		fprintf(fid, '\t\t%-300s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.job,          ':} ', texFormat(tab.job)),		stdRowHeight);
		fprintf(fid, '\t\t%-300s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.telephone,    ':} ', texFormat(tab.telephone)), 	stdRowHeight);
		fprintf(fid, '\t\t%-300s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.email,        ':} ', '\href{mailto:', tab.email, '}{', texFormat(tab.email), '}'),      stdRowHeight);
		% set a very narrow last row
		fprintf(fid, '\t\t%300s & \\\\[%.2fcm] \\hline\n', '', smallRowHeight);
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
    function writeSectBackgrounds(fid, lan, tab, ntab, nsec)
        % write section header
        writeTableSectHeader(fid, lan.header.background, ntab, nsec)
        % write table section
        fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult3N+colWidthPlus3N, colWidthMult3N+colWidthPlus3N, colWidthMult3N+colWidthPlus3N);
		% set a very narrow first row
		fprintf(fid, '\t\t%100s & %100s & %100s & \\\\[%.2fcm]\n', '', '', '', smallRowHeight);
		fprintf(fid, '\t\t%-100s & %-100s & %-100s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.title, '}'),...
                horzcat('\textbf{', lan.university, '}'),...
                horzcat('\textbf{', lan.year, '}'), stdRowHeight);
		for i = 1:length(tab)
			fprintf(fid, '\t\t%-100s & %-100s & %-100s & \\\\[%.2fcm]\n',...
                    texFormat(tab(i).title),...
                    texFormat(tab(i).university),...
                    texFormat(tab(i).year),	stdRowHeight);
		end
		% set a very narrow last row
		fprintf(fid, '\t\t%100s & %100s & %100s & \\\\[%.2fcm] \\hline\n', '', '', '', smallRowHeight);
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
end

function writeTableResearch(fid, lan, tab, ntab)
    %
    % write table with research info
    %
    % load global variables
    global smallRowHeight stdRowHeight colWidthMult1N colWidthMult2N colWidthMult3N colWidthMult5N colWidthPlus5N texFormat
	% local variables
	nsec = 0;
    % write table header
    writeTableHeader(fid, lan.header.research, ntab)
    % write sections
    if isfield(tab, 'projects')
		nsec = nsec + 1;
        writeSectProjects(fid, lan, tab.projects, ntab, nsec)
    end
    if isfield(tab, 'publications')
		nsec = nsec + 1;
        writeSectPublications(fid, lan, tab.publications, ntab, nsec)
    end
	if isfield(tab, 'patents')
		nsec = nsec + 1;
        writeSectPatents(fid, lan, tab.patents, ntab, nsec)
    end
    if isfield(tab, 'collaborations')
		nsec = nsec + 1;
        writeSectCollaborations(fid, lan, tab.collaborations, ntab, nsec)
    end
    if isfield(tab, 'internships')
		nsec = nsec + 1;
        writeSectInternships(fid, lan, tab.internships, ntab, nsec)
    end
    if isfield(tab, 'scholarships')
		nsec = nsec + 1;
        writeSectScholarships(fid, lan, tab.scholarships, ntab, nsec)
    end
    if isfield(tab, 'codes')
		nsec = nsec + 1;
        writeSectCodes(fid, lan, tab.codes, ntab, nsec)
    end
    fprintf(fid, '\t\\newpage\n\n');
    % function definition for sections
	function writeSectProjects(fid, lan, tab, ntab, nsec)
        % load global variables
        global args
        % write section header
        writeTableSectHeader(fid, lan.header.res_projects, ntab, nsec)
        % write table section
        fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}L{%.3f\\linewidth}N}\n', colWidthMult2N, colWidthMult2N);
		for i = 1:length(tab)
			% set a very narrow first row
			fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
			fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
					horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.title, ':} ',  texFormat(tab(i).title),  '}'), stdRowHeight);
			fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
                    horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.entity, ':} ', texFormat(tab(i).entity), '}'), stdRowHeight);
			fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
                    horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.leader, ':} ', texFormat(tab(i).leader), '}'), stdRowHeight);
            if strcmp(args.language, 'en')
                fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
                        horzcat('\textbf{', lan.sdate,   ':} ',  texFormat(tab(i).sdate)),...
                        horzcat('\textbf{', lan.amount,  ':} ',  texFormat(lan.currency),            texFormat(tab(i).amount)),	stdRowHeight);
            else
                fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
                    	horzcat('\textbf{', lan.sdate,   ':} ',  texFormat(tab(i).sdate)),...
                        horzcat('\textbf{', lan.amount,  ':} ',  texFormat(tab(i).amount),   '~',    texFormat(lan.currency)),	stdRowHeight);
            end
			fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
					horzcat('\textbf{', lan.edate,   ':} ',	texFormat(tab(i).edate)),...
                    horzcat('\textbf{', lan.people,  ':} ',	texFormat(tab(i).people)),		stdRowHeight);
			% set a very narrow last row
			fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm] \\hline\n', '', '', smallRowHeight);
		end
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
	function writeSectPublications(fid, lan, tab, ntab, nsec)
		% local variables
		nsub = 0;
        % write section header
        writeTableSectHeader(fid, lan.header.res_publications, ntab, nsec)
        if isfield(tab, 'papers')
			nsub = nsub + 1;
            writeSubSectPapers(fid, lan, tab.papers, ntab, nsec,nsub)
        end
        if isfield(tab, 'books')
			nsub = nsub + 1;
            writeSubSectBooks(fid, lan, tab.books, ntab, nsec,nsub)
        end
        if isfield(tab, 'int_conferences')
			nsub = nsub + 1;
            writeSubSectIntConferences(fid, lan, tab.int_conferences, ntab, nsec,nsub)
        end
        if isfield(tab, 'nat_conferences')
			nsub = nsub + 1;
            writeSubSectNatConferences(fid, lan, tab.nat_conferences, ntab, nsec,nsub)
        end
        %function definition for sub-sections
		function writeSubSectPapers(fid, lan, tab, ntab, nsec, nsub)
			% write sub-section header
            writeTableSubSectHeader(fid, lan.header.res_papers, ntab, nsec, nsub)
            % write table sub-section
            fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}L{%.3f\\linewidth}L{%.3f\\linewidth}N}\n', colWidthMult3N, colWidthMult3N, colWidthMult3N);
			for i = 1:length(tab)
                % replace last comma of authors by copulative conjunction (and)
                tmp=strfind(tab(i).authors, ', ');
                if ~isempty(tmp)
                    tab(i).authors=horzcat(tab(i).authors(1:tmp(end)-1), ' ', lan.and, ' ', tab(i).authors(tmp(end)+2:end));
                end
				% set a very narrow first row
				fprintf(fid, '\t\t%100s & %100s & %100s & \\\\[%.2fcm]\n', '', '', '', smallRowHeight);
				fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
						horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.authors,   ':} ',  texFormat(tab(i).authors),      '}'),	stdRowHeight);
                if isempty(tab(i).link)
                    fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
                            horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.title,     ':} ',  texFormat(tab(i).title),        '}'), 	stdRowHeight);
                else
                    fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
                            horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.title,     ':} \href{', tab(i).link, '}{', texFormat(tab(i).title), '}}'), 	stdRowHeight);
                end
				fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
                        horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.journal,   ':} ',  texFormat(tab(i).journal),      '}'),   stdRowHeight);
				fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
                        horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.publisher,	':} ',  texFormat(tab(i).publisher),    '}'), 	stdRowHeight);
				fprintf(fid, '\t\t%-150s & %-150s    & \\\\[%.2fcm]\n',...
						horzcat('\multicolumn{2}{p{',num2str(2*colWidthMult3N), '\linewidth}}{\textbf{', lan.reference,    ':} ',	texFormat(tab(i).reference), '}'),...
                        horzcat('\textbf{', lan.contribution, ':} ',    texFormat(tab(i).contribution)),    stdRowHeight);
                fprintf(fid, '\t\t%-100s & %-100s & %-100s & \\\\[%.2fcm]\n',...
						horzcat('\textbf{', lan.volume,	     ':} ',	   texFormat(tab(i).volume)),...
                        horzcat('\textbf{', lan.pages,	     ':} ',	   texFormat(tab(i).pages)),...
                        horzcat('\textbf{', lan.year,	     ':} ',    texFormat(tab(i).year)),			   stdRowHeight);
				% set a very narrow last row
				fprintf(fid, '\t\t%100s & %100s & %100s & \\\\[%.2fcm] \\hline\n', '', '', '', smallRowHeight);
			end
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
		function writeSubSectBooks(fid, lan, tab, ntab, nsec, nsub)
			% write sub-section header
            writeTableSubSectHeader(fid, lan.header.res_books, ntab, nsec, nsub)
            % write table sub-section
            fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}L{%.3f\\linewidth}L{%.3f\\linewidth}N}\n', colWidthMult3N, colWidthMult3N, colWidthMult3N);
			for i = 1:length(tab)
                % replace last comma of authors by copulative conjunction (and)
                tmp=strfind(tab(i).authors, ', ');
                if ~isempty(tmp)
                    tab(i).authors=horzcat(tab(i).authors(1:tmp(end)-1), ' ', lan.and, ' ', tab(i).authors(tmp(end)+2:end));
                end
				% set a very narrow first row
				fprintf(fid, '\t\t%100s & %100s & %100s & \\\\[%.2fcm]\n', '', '', '', smallRowHeight);
				fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
						horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.authors,	':} ',   texFormat(tab(i).authors),     '}'), 	stdRowHeight);
                if isempty(tab(i).link)
                    fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
                            horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.title,     ':} ',  texFormat(tab(i).title),        '}'), 	stdRowHeight);
                else
                    fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
                            horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.title,     ':} \href{', tab(i).link, '}{', texFormat(tab(i).title), '}}'), 	stdRowHeight);
                end
				fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
                        horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.publisher,	':} ',   texFormat(tab(i).publisher),   '}'), 	stdRowHeight);
				fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
                        horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.reference,	':} ',   texFormat(tab(i).reference),   '}'), 	stdRowHeight);
                fprintf(fid, '\t\t%-100s & %-100s & %-100s & \\\\[%.2fcm]\n',...
                        horzcat('\textbf{', lan.contribution,    ':} ',  texFormat(tab(i).contribution)),...
                        horzcat('\textbf{', lan.pages,           ':} ',	texFormat(tab(i).pages)),...
                        horzcat('\textbf{', lan.year,            ':} ',	texFormat(tab(i).year)),			stdRowHeight);
				% set a very narrow last row
                fprintf(fid, '\t\t%100s & %100s & %100s & \\\\[%.2fcm] \\hline\n', '', '', '', smallRowHeight);
			end
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
		function writeSubSectIntConferences(fid, lan, tab, ntab, nsec, nsub)
			% write sub-section header
            writeTableSubSectHeader(fid, lan.header.res_int_conferences, ntab, nsec, nsub)
            % write table sub-section
            fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}L{%.3f\\linewidth}N}\n', colWidthMult2N, colWidthMult2N);
            for i = 1:length(tab)
                % replace last comma of authors by copulative conjunction (and)
                tmp=strfind(tab(i).authors, ', ');
                if ~isempty(tmp)
                    tab(i).authors=horzcat(tab(i).authors(1:tmp(end)-1), ' ', lan.and, ' ', tab(i).authors(tmp(end)+2:end));
                end
				% set a very narrow first row
				fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
				fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
						horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.authors,	':} ',	texFormat(tab(i).authors),          '}'), 		stdRowHeight);
				fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
						horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.title,	    ':} ',	texFormat(tab(i).title),            '}'), 		stdRowHeight);
                if isempty(tab(i).link)
    				fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
                            horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.conference,	':} ',	texFormat(tab(i).conference),   '}'),       stdRowHeight);
                else
                    fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
                            horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.conference,	':} \href{', tab(i).link, '}{', texFormat(tab(i).conference), '}}'), 	stdRowHeight);
                end
				fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
                        horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.location,	':} ',	texFormat(tab(i).location),         '}'),       stdRowHeight);
				fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
                        horzcat('\textbf{', lan.reference,	':} ',    texFormat(tab(i).reference)),...
                        horzcat('\textbf{', lan.date,    	':} ',    texFormat(tab(i).date)),         stdRowHeight);
				fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
                        horzcat('\textbf{', lan.contribution, ':} ',   texFormat(tab(i).contribution)),...
                        horzcat('\textbf{', lan.pages,		':} ',    texFormat(tab(i).pages)),        stdRowHeight);
				% set a very narrow last row
                fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm] \\hline\n', '', '', smallRowHeight);
			end
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
		function writeSubSectNatConferences(fid, lan, tab, ntab, nsec, nsub)
			% write sub-section header
            writeTableSubSectHeader(fid, lan.header.res_nat_conferences, ntab, nsec, nsub)
            % write table sub-section
            fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}L{%.3f\\linewidth}N}\n', colWidthMult2N, colWidthMult2N);
            for i = 1:length(tab)
                % replace last comma of authors by copulative conjunction (and)
                tmp=strfind(tab(i).authors, ', ');
                if ~isempty(tmp)
                    tab(i).authors=horzcat(tab(i).authors(1:tmp(end)-1), ' ', lan.and, ' ', tab(i).authors(tmp(end)+2:end));
                end
				% set a very narrow first row
				fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm] \n', '', '', smallRowHeight);
				fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
                        horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.authors,	':} ',    	texFormat(tab(i).authors),          '}'), 	stdRowHeight);
				fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
                        horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.title,  	':} ',     	texFormat(tab(i).title),            '}'), 	stdRowHeight);
                if isempty(tab(i).link)
    				fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
                            horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.conference,	':} ',	texFormat(tab(i).conference),   '}'),       stdRowHeight);
                else
                    fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
                            horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.conference,	':} \href{', tab(i).link, '}{', texFormat(tab(i).conference), '}}'), 	stdRowHeight);
                end
				fprintf(fid, '\t\t%-300s    & \\\\[%.2fcm]\n',...
						horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.location,	':} ',    	texFormat(tab(i).location),         '}'),   stdRowHeight);
				fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
                        horzcat('\textbf{', lan.reference,	 ':} ',    texFormat(tab(i).reference)),...
                        horzcat('\textbf{', lan.date,    	 ':} ',    texFormat(tab(i).date)),         stdRowHeight);
				fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
                        horzcat('\textbf{', lan.contribution, ':} ',    texFormat(tab(i).contribution)),...
                        horzcat('\textbf{', lan.pages,		 ':} ',    texFormat(tab(i).pages)),        stdRowHeight);
				% set a very narrow last row
				fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm] \\hline\n', '', '', smallRowHeight);
			end
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
    end
	function writeSectPatents(fid, lan, tab, ntab, nsec)
		% write section header
		writeTableSectHeader(fid, lan.header.res_patents, ntab, nsec)
		% write table sub-section
		fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}L{%.3f\\linewidth}L{%.3f\\linewidth}N}\n', colWidthMult3N, colWidthMult3N, colWidthMult3N);
		for i = 1:length(tab)
            % replace last comma of authors by copulative conjunction (and)
            tmp=strfind(tab(i).authors, ', ');
            if ~isempty(tmp)
                tab(i).authors=horzcat(tab(i).authors(1:tmp(end)-1), ' ', lan.and, ' ', tab(i).authors(tmp(end)+2:end));
            end            
			% set a very narrow first row
			fprintf(fid, '\t\t%100s & %100s & %100s & \\\\[%.2fcm]\n', '', '', '', smallRowHeight);
			fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
                    horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.authors,	':} ',	texFormat(tab(i).authors),      '}'),   stdRowHeight);
			fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
					horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.title,      ':} ', texFormat(tab(i).title),        '}'),   stdRowHeight);
			fprintf(fid, '\t\t%-300s       & \\\\[%.2fcm]\n',...
					horzcat('\multicolumn{3}{p{\linewidth}}{\textbf{', lan.description, ':} ', texFormat(tab(i).description),  '}'),   stdRowHeight);
			fprintf(fid, '\t\t%100s & %100s & %100s & \\\\[%.2fcm]\n',...
                    horzcat('\textbf{', lan.type,	':} ',    texFormat(tab(i).type)),...
                    horzcat('\textbf{', lan.number,	':} ',    texFormat(tab(i).number)),...
                    horzcat('\textbf{', lan.date,	':} ',    texFormat(tab(i).date)),			stdRowHeight);
			% set a very narrow last row
			fprintf(fid, '\t\t%100s & %100s & %100s & \\\\[%.2fcm] \\hline\n', '', '', '', smallRowHeight);
		end
		fprintf(fid, '\t\\end{longtable}\n');
		fprintf(fid, '\n');
	end
	function writeSectCollaborations(fid, lan, tab, ntab, nsec)
        % write section header
        writeTableSectHeader(fid, lan.header.res_collaborations, ntab, nsec)
        % write table section
        fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
		for i = 1:length(tab)
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
			fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
								texFormat(tab(i).sdate),   texFormat(tab(i).group));
			fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
								texFormat(tab(i).edate),   horzcat(texFormat(tab(i).department), ' ', lan.at, ' ', texFormat(tab(i).university)));
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
        end
        fprintf(fid, '\t\t\\hline\n');
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
	function writeSectInternships(fid, lan, tab, ntab, nsec)
        % write section header
        writeTableSectHeader(fid, lan.header.res_internships, ntab, nsec)
		% write table section
        fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
		for i = 1:length(tab)
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
			fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
								texFormat(tab(i).edate),   horzcat(texFormat(tab(i).university), ', ', texFormat(tab(i).location)));
            fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
								texFormat(tab(i).sdate),   horzcat(texFormat(tab(i).description), ' ', lan.with, ' ', texFormat(tab(i).advisor)));
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
        end
        fprintf(fid, '\t\t\\hline\n');
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
	function writeSectScholarships(fid, lan, tab, ntab, nsec)
        % load global variables
        global args
        % write section header
        writeTableSectHeader(fid, lan.header.res_scholarships, ntab, nsec)
		% write table section
        fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
		for i = 1:length(tab)
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
			fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
					horzcat('\multirow{2}{*}{', texFormat(tab(i).year), '}'),...
                    texFormat(tab(i).title));
            if strcmp(args.language, 'en')
                fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
                        '',	horzcat(texFormat(tab(i).description), ', ', texFormat(lan.currency),     texFormat(tab(i).amount), ', ', texFormat(tab(i).duration), ' ', lan.mth, ' ', lan.in, ' ', texFormat(tab(i).location)));
            else
                fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
                        '',	horzcat(texFormat(tab(i).description), ', ', texFormat(tab(i).amount), '~', texFormat(lan.currency), ', ', texFormat(tab(i).duration), ' ', lan.mth, ' ', lan.in, ' ', texFormat(tab(i).location)));
            end
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
		end
		fprintf(fid, '\t\t\\hline\n');
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
    function writeSectCodes(fid, lan, tab, ntab, nsec)
        % write section header
        writeTableSectHeader(fid, lan.header.res_codes, ntab, nsec)
		% write table section
        fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
		for i = 1:length(tab)
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
            if isempty(tab(i).link)
                fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
                        horzcat('\multirow{2}{*}{', texFormat(tab(i).short), '}'),...
                        texFormat(tab(i).long));
            else
                fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
					horzcat('\multirow{2}{*}{\href{', tab(i).link, '}{', texFormat(tab(i).short), '}}'),...
                    texFormat(tab(i).long));
            end
            fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
                    '',	texFormat(tab(i).description));
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
		end
		fprintf(fid, '\t\t\\hline\n');
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
end

function writeTableTeaching(fid, lan, tab, ntab)
	%
    % write table with teaching info
    %
    % load global variables
    global smallRowHeight stdRowHeight colWidthMult1N colWidthMult2N colWidthMult5N colWidthPlus5N texFormat
	% local variables
	nsec = 0;
    % write table header
    writeTableHeader(fid, lan.header.teaching, ntab)
    % write sections
	if isfield(tab, 'subjects')
		nsec = nsec + 1;
        writeSectSubjects(fid, lan, tab.subjects, ntab, nsec)
    end
    if isfield(tab, 'giv_courses')
		nsec = nsec + 1;
        writeSectGivCourses(fid, lan, tab.giv_courses, ntab, nsec)
    end
    if isfield(tab, 'giv_seminars')
		nsec = nsec + 1;
        writeSectGivSeminars(fid, lan, tab.giv_seminars, ntab, nsec)
    end
    if isfield(tab, 'giv_workshops')
		nsec = nsec + 1;
        writeSectGivWorkshops(fid, lan, tab.giv_workshops, ntab, nsec)
    end
    if isfield(tab, 'materials')
		nsec = nsec + 1;
        writeSectMaterials(fid, lan, tab.materials, ntab, nsec)
    end
    fprintf(fid, '\t\\newpage\n\n');
    % function definition for sections
	function writeSectSubjects(fid, lan, tab, ntab, nsec)
        % write section header
        writeTableSectHeader(fid, lan.header.tea_subjects, ntab, nsec)
        % write table section
        fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}L{%.3f\\linewidth}N}\n', colWidthMult2N, colWidthMult2N);
		for i = 1:length(tab)
			% set a very narrow first row
			fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
			fprintf(fid, '\t\t%-300s  & \\\\[%.2fcm]\n',...
					horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.subject,    ':} ',    texFormat(tab(i).subject),       '}'), 	stdRowHeight);
			fprintf(fid, '\t\t%-300s  & \\\\[%.2fcm]\n',...
					horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.department,	':} ',    texFormat(tab(i).department), '}'),	stdRowHeight);
			fprintf(fid, '\t\t%-300s  & \\\\[%.2fcm]\n',...
					horzcat('\multicolumn{2}{p{\linewidth}}{\textbf{', lan.university,	':} ',    texFormat(tab(i).university), '}'),	stdRowHeight);
			fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
                    horzcat('\textbf{', lan.plan,	':} ',    texFormat(tab(i).plan)),...
                    horzcat('\textbf{', lan.grade,	':} ',    texFormat(tab(i).grade)),		stdRowHeight);
			fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
                    horzcat('\textbf{', lan.type,	':} ',    texFormat(tab(i).type)),...
                    horzcat('\textbf{', lan.hours,	':} ',    texFormat(tab(i).hours)),		stdRowHeight);
			% set a very narrow last row
			fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm] \\hline\n', '', '', smallRowHeight);
		end
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
	function writeSectGivCourses(fid, lan, tab, ntab, nsec)
        % write section header
        writeTableSectHeader(fid, lan.header.tea_courses, ntab, nsec)
		% write table section
        fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
        fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
		for i = 1:length(tab)
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
			fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
					texFormat(tab(i).year),...
                    horzcat('\textit{', texFormat(tab(i).title), '} - ', texFormat(tab(i).entity), ' - ', texFormat(tab(i).duration), '~', lan.abH));
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
        end
        fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm] \\hline\n', '', '', smallRowHeight);
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
	function writeSectGivSeminars(fid, lan, tab, ntab, nsec)
        % write section header
        writeTableSectHeader(fid, lan.header.tea_seminars, ntab, nsec)
		% write table section
        fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
        fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
		for i = 1:length(tab)
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
			fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
					texFormat(tab(i).year),...
                    horzcat('\textit{', texFormat(tab(i).title), '} - ', texFormat(tab(i).entity), ' - ', texFormat(tab(i).duration), '~', lan.abH));
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
        end
        fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm] \\hline\n', '', '', smallRowHeight);
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
	function writeSectGivWorkshops(fid, lan, tab, ntab, nsec)
        % write section header
        writeTableSectHeader(fid, lan.header.tea_workshops, ntab, nsec)
		% write table section
        fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
        fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
		for i = 1:length(tab)
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
			fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
					texFormat(tab(i).year),...
                    horzcat('\textit{', texFormat(tab(i).title), '} - ', texFormat(tab(i).entity), ' - ', texFormat(tab(i).duration), '~', lan.abH));
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
        end
        fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm] \\hline\n', '', '', smallRowHeight);
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
	function writeSectMaterials(fid, lan, tab, ntab, nsec)
        % write section header
        writeTableSectHeader(fid, lan.header.tea_materials, ntab, nsec)
		% write table section
        fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
        fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
		for i = 1:length(tab)
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
			fprintf(fid, '\t\t%-60s & %-240s & \\\\\n',...
					texFormat(tab(i).year),...
                    horzcat('\textit{', texFormat(tab(i).title), '} - ', texFormat(tab(i).publisher), ' - ', lan.abRef, '.~', texFormat(tab(i).reference)));
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm] \\hline\n', '', '', smallRowHeight);
        end
        fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
    end
end

function writeTableExperience(fid, lan, tab, ntab)
    %
    % write table with previous experience info
    %
    % load global variables
    global smallRowHeight colWidthMult1N colWidthMult5N colWidthPlus5N texFormat
    % write table header
    writeTableHeader(fid, lan.header.experience, ntab)
    % write table
	fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
    fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
	for i = 1:length(tab)
		% set a very narrow first row
		fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
		fprintf(fid, '\t\t%-60s & %-240s & \\\\*\n',...
							texFormat(tab(i).edate),   horzcat('\textit{', texFormat(tab(i).company),   '}'));
		fprintf(fid, '\t\t%-60s & %-240s & \\\\*\n',...
							texFormat(tab(i).sdate),   texFormat(tab(i).description));
		% set a very narrow last row
		fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
    end
    fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\\hline\n', '', '', smallRowHeight);
    fprintf(fid, '\t\\end{longtable}\n');
    fprintf(fid, '\n');
    fprintf(fid, '\t\\newpage\n\n');
end

function writeTableOther(fid, lan, tab, ntab)
    %
    % write table with other achievements info
    %
    % load global variables
    global smallRowHeight stdRowHeight colWidthMult1N colWidthPlus1N colWidthMult3N colWidthMult4N colWidthMult5N colWidthPlus5N texFormat
	% local variables
	nsec = 0;
    % write table header
    writeTableHeader(fid, lan.header.other, ntab)
    % write sections
    if isfield(tab, 'languages') && isfield(tab.languages, 'languages')
		nsec = nsec + 1;
        writeSectLanguages(fid, lan, tab.languages, ntab, nsec)
    end
    if isfield(tab, 'courses')
		nsec = nsec + 1;
        writeSectCourses(fid, lan, tab.courses, ntab, nsec)
    end
    if isfield(tab, 'computer')
		nsec = nsec + 1;
        writeSectComputer(fid, lan, tab.computer, ntab, nsec)
    end
    % function definition for sections
	function writeSectLanguages(fid, lan, tab, ntab, nsec)
		% local variables
		nsub = 0;
        % write section header
        writeTableSectHeader(fid, lan.header.oth_languages, ntab, nsec)
        % write table section
        fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult4N, colWidthMult4N, colWidthMult4N, colWidthMult4N);
		% set a very narrow first row
		fprintf(fid, '\t\t%75s & %75s & %75s & %75s & \\\\[%.2fcm]\n', '', '', '', '', smallRowHeight);
		fprintf(fid, '\t\t%-75s & %-75s & %-75s & %-75s & \\\\[%.2fcm]\n',...
				horzcat('\textbf{', lan.language,    '}'),...
                horzcat('\textbf{', lan.listening,   '}'),...
                horzcat('\textbf{', lan.speaking,    '}'),...
                horzcat('\textbf{', lan.writing,     '}'),                 stdRowHeight);
        for i = 1:length(tab.languages)
			fprintf(fid, '\t\t%-75s & %-75s & %-75s & %-75s & \\\\[%.2fcm]\n',...
					texFormat(tab.languages(i).language),	texFormat(tab.languages(i).listening),	texFormat(tab.languages(i).speaking),	texFormat(tab.languages(i).writing),   stdRowHeight);
		end
		% set a very narrow last row
		fprintf(fid, '\t\t%75s & %75s & %75s & %75s & \\\\[%.2fcm] \\hline\n', '', '', '', '', smallRowHeight);
		fprintf(fid, '\t\\end{longtable}\n');
        fprintf(fid, '\n');
        if isfield(tab, 'lan_titles')
			nsub = nsub + 1;
            writeSubSectTitles(fid, lan, tab.lan_titles, ntab, nsec, nsub)
        end
        % function definition for sub-sections
		function writeSubSectTitles(fid, lan, tab, ntab, nsec, nsub)
			% write sub-section header
            writeTableSubSectHeader(fid, lan.header.oth_lan_titles, ntab, nsec, nsub)
			% write table sub-section
			fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', 0.5*smallRowHeight);
			for i = 1:length(tab)
				fprintf(fid, '\t\t%-60s & %-240s & \\\\[%.2fcm]\n',...
						texFormat(tab(i).year),...
                        horzcat('\textit{',  texFormat(tab(i).title),  '} - ',  texFormat(tab(i).entity)),		stdRowHeight);
			end
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm] \\hline\n', '', '', 0.5*smallRowHeight);
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
    end
	function writeSectCourses(fid, lan, tab, ntab, nsec)
		% local variables
		nsub = 0;
        % write section header
        writeTableSectHeader(fid, lan.header.oth_courses, ntab, nsec)
        if isfield(tab, 'tec_courses')
			nsub = nsub + 1;
            writeSubSectTecCourses(fid, lan, tab.tec_courses, ntab, nsec, nsub)
        end
        if isfield(tab, 'tec_seminars')
			nsub = nsub + 1;
            writeSubSectTecSeminars(fid, lan, tab.tec_seminars, ntab, nsec, nsub)
        end
        if isfield(tab, 'tec_workshops')
			nsub = nsub + 1;
            writeSubSectTecWorkshops(fid, lan, tab.tec_workshops, ntab, nsec, nsub)
        end
        if isfield(tab, 'lan_courses')
			nsub = nsub + 1;
            writeSubSectLanCourses(fid, lan, tab.lan_courses, ntab, nsec, nsub)
        end
        % function definition for sub-sections
		function writeSubSectTecCourses(fid, lan, tab, ntab, nsec, nsub)
			% write sub-section header
            writeTableSubSectHeader(fid, lan.header.oth_tec_courses, ntab, nsec, nsub)
            % write table sub-section
			fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', 0.5*smallRowHeight);
			for i = 1:length(tab)
				fprintf(fid, '\t\t%-60s & %-240s & \\\\[%.2fcm]\n',...
						texFormat(tab(i).year),...
                        horzcat('\textit{', texFormat(tab(i).title), '} - ', texFormat(tab(i).entity), ' - ', texFormat(tab(i).duration), '~', lan.abH),    stdRowHeight);
			end
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm] \\hline\n', '', '', 0.5*smallRowHeight);
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
		function writeSubSectTecSeminars(fid, lan, tab, ntab, nsec, nsub)
			% write sub-section header
            writeTableSubSectHeader(fid, lan.header.oth_tec_seminars, ntab, nsec, nsub)
            % write table sub-section
			fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', 0.5*smallRowHeight);
			for i = 1:length(tab)
 				fprintf(fid, '\t\t%-60s & %-240s & \\\\[%.2fcm]\n',...
						texFormat(tab(i).year),...
                        horzcat('\textit{', texFormat(tab(i).title), '} - ', texFormat(tab(i).entity), ' - ', texFormat(tab(i).duration), '~', lan.abH),    stdRowHeight);
			end
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm] \\hline\n', '', '', 0.5*smallRowHeight);
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
		function writeSubSectTecWorkshops(fid, lan, tab, ntab, nsec, nsub)
			% write sub-section header
            writeTableSubSectHeader(fid, lan.header.oth_tec_workshops, ntab, nsec, nsub)
            % write table sub-section
			fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', 0.5*smallRowHeight);
			for i = 1:length(tab)
 				fprintf(fid, '\t\t%-60s & %-240s & \\\\[%.2fcm]\n',...
						texFormat(tab(i).year),...
                        horzcat('\textit{', texFormat(tab(i).title), '} - ', texFormat(tab(i).entity), ' - ', texFormat(tab(i).duration), '~', lan.abH),    stdRowHeight);
			end
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm] \\hline\n', '', '', 0.5*smallRowHeight);
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
		function writeSubSectLanCourses(fid, lan, tab, ntab, nsec, nsub)
			% write sub-section header
            writeTableSubSectHeader(fid, lan.header.oth_lan_courses, ntab, nsec, nsub)
            % write table sub-section
			fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{%.3f\\linewidth}N}\n', colWidthMult5N+colWidthPlus5N, colWidthMult1N-colWidthMult5N+colWidthPlus5N);
			% set a very narrow first row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm]\n', '', '', 0.5*smallRowHeight);
			for i = 1:length(tab)
				fprintf(fid, '\t\t%-60s & %-240s & \\\\[%.2fcm]\n',...
    					texFormat(tab(i).year),...
                        horzcat('\textit{', texFormat(tab(i).title), '} - ', texFormat(tab(i).entity), ' - ', texFormat(tab(i).location)),  stdRowHeight);
			end
			% set a very narrow last row
			fprintf(fid, '\t\t%60s & %240s & \\\\[%.2fcm] \\hline\n', '', '', 0.5*smallRowHeight);
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
    end
	function writeSectComputer(fid, lan, tab, ntab, nsec)
		% local variables
		nsub = 0;
        % write section header
        writeTableSectHeader(fid, lan.header.oth_computer, ntab, nsec)
        if isfield(tab, 'sof_generals')
			nsub = nsub + 1;
            writeSubSectSoftGeneral(fid, lan, tab.sof_generals, ntab, nsec, nsub)
        end
        if isfield(tab, 'sof_developers')
			nsub = nsub + 1;
            writeSubSectSoftDeveloper(fid, lan, tab.sof_developers, ntab, nsec, nsub)
        end
        if isfield(tab, 'sof_specifics')
			nsub = nsub + 1;
            writeSubSectSoftSpecific(fid, lan, tab.sof_specifics, ntab, nsec, nsub)
        end
        % function definition for sub-sections
		function writeSubSectSoftGeneral(fid, lan, tab, ntab, nsec, nsub)
            % write sub-section header
            writeTableSubSectHeader(fid, lan.header.oth_sof_general, ntab, nsec, nsub)
            % write table sub-section
			fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}N}\n', colWidthMult1N+colWidthPlus1N);
			% set a very narrow first row
			fprintf(fid, '\t\t%300s & \\\\[%.2fcm]\n', '', smallRowHeight);
			for i = 1:length(tab)
				fprintf(fid, '\t\t%-300s & \\\\[%.2fcm]\n',...
						texFormat(tab(i).software),		stdRowHeight);
			end
			% set a very narrow last row
			fprintf(fid, '\t\t%300s & \\\\[%.2fcm] \\hline\n', '', smallRowHeight);
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
		function writeSubSectSoftDeveloper(fid, lan, tab, ntab, nsec, nsub)
			% write sub-section header
            writeTableSubSectHeader(fid, lan.header.oth_sof_developer, ntab, nsec, nsub)
            % write table sub-section
			fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}N}\n', colWidthMult1N+colWidthPlus1N);
			% set a very narrow first row
			fprintf(fid, '\t\t%300s & \\\\[%.2fcm]\n', '', smallRowHeight);
			for i = 1:length(tab)
				fprintf(fid, '\t\t%-300s & \\\\[%.2fcm]\n',...
						texFormat(tab(i).software),		stdRowHeight);
			end
			% set a very narrow last row
			fprintf(fid, '\t\t%300s & \\\\[%.2fcm] \\hline\n', '', smallRowHeight);
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
		function writeSubSectSoftSpecific(fid, lan, tab, ntab, nsec, nsub)
			% write sub-section header
            writeTableSubSectHeader(fid, lan.header.oth_sof_specific, ntab, nsec, nsub)
			% write table sub-section
			fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}L{%.3f\\linewidth}N}\n', colWidthMult3N+colWidthPlus5N, colWidthMult1N-colWidthMult3N+colWidthPlus5N);
			% set a very narrow first row
			fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm]\n', '', '', smallRowHeight);
			for i = 1:length(tab)
				fprintf(fid, '\t\t%-150s & %-150s & \\\\[%.2fcm]\n',...
                		texFormat(tab(i).software),   texFormat(tab(i).description),		stdRowHeight);
			end
			% set a very narrow last row
			fprintf(fid, '\t\t%150s & %150s & \\\\[%.2fcm] \\hline\n', '', '', smallRowHeight);
            fprintf(fid, '\t\\end{longtable}\n');
            fprintf(fid, '\n');
		end
    end
end

function writeTableHeader(fid,title, ntab)
    %
    % write talbe header
    %
    % load global variables
    global titleRowHeight titleCellColor colWidthMult1N
	% write table title in tex file as a comment
	fprintf(fid, '\t%s\n', '%'*ones(1,length(title)+4));
	fprintf(fid, '\t%c %s %c\n', '%',upper(title), '%');
	fprintf(fid, '\t%s\n', '%'*ones(1,length(title)+4));
    fprintf(fid, '\n');
    % set bookmark
    fprintf(fid, '\t\\pdfbookmark[0]{%s}{tab:%s}\\label{tab:%s}\n',...
                        title,...
                        upper(arab2roman(ntab)),...
                        upper(arab2roman(ntab)));
    % write table title
    fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}C{0.000\\linewidth}N} \\hhline{1-1}\n', colWidthMult1N);
    fprintf(fid, '\t\t\\cellcolor{%10s}\\textbf{\\Large %s. - %s} & \\\\[%.2fcm] \\hhline{1-1}\n',...
                        titleCellColor,...
                        upper(arab2roman(ntab)),...
                        upper(title),...
                        titleRowHeight);
    fprintf(fid, '\t\\end{longtable}\n');
    fprintf(fid, '\n');
end

function writeTableSectHeader(fid,title, ntab, nsec)
    %
    % write table section header
    %
    % load global variables
    global sectRowHeight colWidthMult1N colWidthPlus1N
	% write table section title in tex file as a comment
    fprintf(fid, '\t%c %-s\n', '%',upper(title));
    fprintf(fid, '\n');
    % set bookmark
    fprintf(fid, '\t\\pdfbookmark[1]{%s}{sec:%s.%i.}\\label{sec:%s.%i.}\n',...
                        title,...
                        upper(arab2roman(ntab)), nsec,...
                        upper(arab2roman(ntab)), nsec);
    % write table section title 
    fprintf(fid, '\t\\begin{longtable}{C{%.3f\\linewidth}N}\n', colWidthMult1N+colWidthPlus1N);
    fprintf(fid, '\t\t\\textbf{\\large %s.%i. - %s} & \\\\[%.2fcm] \\hline\n',...
                        upper(arab2roman(ntab)), nsec,...
                        upper(title),...
                        sectRowHeight);
    fprintf(fid, '\t\\end{longtable}\n');
	fprintf(fid, '\n');
end

function writeTableSubSectHeader(fid,title, ntab, nsec, nsub)
    %
    % write table sub-section header
    %
    % load global variables
    global subSectRowHeight colWidthMult1N colWidthPlus1N
	% write table section title in tex file as a comment
    fprintf(fid, '\t%c %-s\n', '%',title);
    fprintf(fid, '\n');
    % set bookmark
    fprintf(fid, '\t\\pdfbookmark[2]{%s}{sec:%s.%i.%i.}\\label{sec:%s.%i.%i.}\n',...
                        title,...
                        upper(arab2roman(ntab)), nsec, nsub,...
                        upper(arab2roman(ntab)), nsec, nsub);
    % write table section title 
    fprintf(fid, '\t\\begin{longtable}{L{%.3f\\linewidth}N}\n', colWidthMult1N+colWidthPlus1N);
    fprintf(fid, '\t\t\\textbf{\\large %s.%i.%i - %s} & \\\\[%.2fcm] \\hline\n',...
                        upper(arab2roman(ntab)), nsec, nsub,...
                        title,...
                        subSectRowHeight);
    fprintf(fid, '\t\\end{longtable}\n');
	fprintf(fid, '\n');
end

function lan = loadLanguage(args)
    %
    % load language according to user options
    %
    % what date is it today?
    myDate = datevec(datetime('now'));
    day    = myDate(3);
    month  = myDate(2);
    year   = myDate(1);
    %currency is independent of language
    switch args.currency
        case 'eur'
            lan.currency = '€';
        case 'usd'
            lan.currency = '$';
        case 'gbp'
            lan.currency = '£';
        case 'jpy'
            lan.currency = '¥';
    end
	% load all text in language specified by lang
	%please, write all language text following latex and matlab rules (lan.* is not passed through texFormat function due to different encoding among OS)
	switch args.language
		case 'es'
            lan.and                         = 'y';
            lan.abH                         = 'h';
            lan.in                          = 'en';
            lan.at                          = 'de la';
            lan.with                        = 'con';
            lan.abRef                       = 'Ref';
            lan.mth                         = 'meses';
            lan.page                        = 'P\''agina';
            lan.of                          = 'de';
            lan.months                      = {'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'};
			%HEADERS
			lan.header.general				= 'Datos generales';
			lan.header.personal				= 'Datos personales';
			lan.header.company				= 'Situaci\''on actual';
			lan.header.background			= 'Formaci\''on acad\''emica';
			lan.header.research				= 'Investigaci\''on';
			lan.header.res_projects			= 'Participaci\''on en proyectos';
			lan.header.res_publications		= 'Publicaciones';
			lan.header.res_papers			= 'Art\''iculos';
			lan.header.res_books			= 'Libros';
			lan.header.res_int_conferences	= 'Congresos internacionales';
			lan.header.res_nat_conferences	= 'Congresos nacionales';
			lan.header.res_patents			= 'Patentes';
			lan.header.res_collaborations	= 'Colaboraciones';
			lan.header.res_internships		= 'Estancias';
			lan.header.res_scholarships		= 'Becas y ayudas';
            lan.header.res_codes    		= 'C\''odigos desarrollados';
			lan.header.teaching				= 'Docencia';
			lan.header.tea_subjects			= 'Docencia universitaria';
			lan.header.tea_courses			= 'Cursos impartidos';
			lan.header.tea_seminars 		= 'Seminarios impartidos';
			lan.header.tea_workshops 		= 'Talleres impartidos';
			lan.header.tea_materials		= 'Material acad\''emico';
			lan.header.experience			= 'Experiencia profesional';
			lan.header.other				= 'Otros m\''eritos';
			lan.header.oth_languages		= 'Idiomas (nivel europeo)';
			lan.header.oth_lan_titles		= 'T\''itulos oficiales';
			lan.header.oth_courses			= 'Cursos y seminarios';
			lan.header.oth_tec_courses		= 'Cursos recibidos';
			lan.header.oth_tec_seminars		= 'Seminarios recibidos';
			lan.header.oth_tec_workshops	= 'Talleres recibidos';
			lan.header.oth_lan_courses		= 'Curos de idiomas';
			lan.header.oth_computer			= 'Conocimientos inform\''aticos';
			lan.header.oth_sof_general		= 'Uso general';
			lan.header.oth_sof_developer	= 'Desarrollador';
			lan.header.oth_sof_specific		= 'Programas espec\''ificos';
            %TITLE PAGE
			lan.cvtitle		= 'Curriculum vitae';
			lan.pages		= 'N\''umero de hojas que contiene';
			lan.name		= 'Nombre';
			lan.date		= 'Fecha';
			lan.disclaimer	= 'La persona arriba indicada declara que son ciertos los datos que figuran en este curr\''iculum; asumiendo, en caso contrario, las responsabilidades que pudieran derivarse de las inexactitudes que consten en el mismo.';
			lan.frontDate	= horzcat(num2str(day, '%2i'), ' ', lan.of, ' ', lan.months{month}, ' ', lan.of, ' ', num2str(year));
            %GENERAL DATA
			%Personal data
			lan.surname		= 'Apellidos';
			lan.id			= 'DNI';
			lan.birth		= 'Fecha de nacimiento';
			lan.telephone	= 'Tel\''efono';
			lan.address		= 'Direcci\''on';
			lan.city		= 'Ciudad';
			lan.code		= 'C\''odigo postal';
			%Current situation
			lan.employer	= 'Empresa';
			lan.department	= 'Departamento';
			lan.job			= 'Puesto';
			lan.email		= 'Correo electr\''onico';
			%Academic background
			lan.title		= 'T\''itulo';
			lan.university	= 'Universidad';
			lan.year		= 'A\~no';
			%RESEARCH
			%Projects
			lan.entity		= 'Entidad financiera';
			lan.leader		= 'Investigador principal';
			lan.sdate		= 'Desde';
			lan.edate		= 'Hasta';
			lan.amount		= 'Importe de la subvenci\''on';
			lan.people		= 'N\''umero de investigadores';
			%Papers
			lan.authors		= 'Autores';
			lan.publisher	= 'Editorial';
			lan.journal		= 'Revista';
			lan.reference	= 'Refer\''encia';
			lan.volume		= 'Volumen';
			lan.pages		= 'P\''aginas';
			%Conferences   
			lan.conference	= 'Congreso';
			lan.location	= 'Lugar de celebraci\''on';
			lan.contribution= 'Contribuci\''on';
			%Patents
			lan.description	= 'Descripci\''on';
			lan.number		= 'N\''umero';
			lan.cdate		= 'Fecha concesi\''on';
			lan.type		= 'Tipo';
			%TEACHING
			%Subjects
			lan.subject		= 'Asignatura';
			lan.plan		= 'Plan';
			lan.grade		= 'Curso';
			lan.hours		= 'N\''umero de horas';
			%OTHER ACHIEVEMENTS
			%Languages
			lan.language	= 'Idioma';
			lan.listening	= 'Comprensi\''on';
			lan.speaking	= 'Habla';
			lan.writing		= 'Escritura';
        case 'ca'
            lan.and                         = 'i';
            lan.abH                         = 'h';
            lan.in                          = 'a';
            lan.at                          = 'de la';
            lan.with                        = 'amb';
            lan.abRef                       = 'Ref';
            lan.mth                         = 'mesos';
            lan.page                        = 'P\`agina';
            lan.of                          = {'de ', 'de ', 'de ', 'd''', 'de ', 'de ', 'de ', 'd''', 'de ', 'd''', 'de ', 'de '};
            lan.months                      = {'gener', 'febrer', 'mar\c{c}', 'abril', 'maig', 'juny', 'juliol', 'agost', 'setembre', 'octubre', 'novembre', 'desembre'};
			%HEADERS
			lan.header.general				= 'Dades generals';
			lan.header.personal				= 'Dades personals';
			lan.header.company				= 'Situaci\''o actual';
			lan.header.background			= 'Formaci\''o acad\`emica';
			lan.header.research				= 'Recerca';
			lan.header.res_projects			= 'Participaci\''o en projectes';
			lan.header.res_publications		= 'Publicacions';
			lan.header.res_papers			= 'Articles';
			lan.header.res_books			= 'Llibres';
			lan.header.res_int_conferences	= 'Congressos internacionals';
			lan.header.res_nat_conferences	= 'Congressos nacionals';
			lan.header.res_patents			= 'Patents';
			lan.header.res_collaborations	= 'Col$\cdot$laboracions';
			lan.header.res_internships		= 'Estades';
			lan.header.res_scholarships		= 'Beques i ajudes';
			lan.header.res_codes    		= 'Codis desenvolupats';
            lan.header.teaching				= 'Doc\`encia';
			lan.header.tea_subjects			= 'Doc\`encia universit\`aria';
			lan.header.tea_courses			= 'Cursos impartits';
			lan.header.tea_seminars 		= 'Seminaris impartits';
			lan.header.tea_workshops 		= 'Tallers impartits';
			lan.header.tea_materials		= 'Material acad\`emic';
			lan.header.experience			= 'Experi\`encia professional';
			lan.header.other				= 'Altres m\`erits';
			lan.header.oth_languages		= 'Idiomes (nivell europeu)';
			lan.header.oth_lan_titles		= 'T\''ituls oficials';
			lan.header.oth_courses			= 'Cursos i seminaris';
			lan.header.oth_tec_courses		= 'Cursos rebuts';
			lan.header.oth_tec_seminars		= 'Seminaris rebuts';
			lan.header.oth_tec_workshops	= 'Tallers rebuts';
			lan.header.oth_lan_courses		= 'Curos d''idiomes';
			lan.header.oth_computer			= 'Coneixements d''inform\`atica';
			lan.header.oth_sof_general		= '\''Us general';
			lan.header.oth_sof_developer	= 'Desenvolupament';
			lan.header.oth_sof_specific		= 'Programes espec\''ifics';
			%TITLE PAGE
			lan.cvtitle		= 'Curriculum vitae';
			lan.pages		= 'Nombre de fulles que cont\''e';
			lan.name		= 'Nom';
			lan.date		= 'Data';
			lan.disclaimer	= 'La persona a dalt indicada declara que s\''on certes les dades que figuren en aquest curr\''iculum; assumint, en cas contrari, les responsabilitats que pogueren derivar-se de les inexactituds que consten en el mateix.';
			lan.frontDate	= horzcat(num2str(day, '%2i'), ' ', lan.of{month}, lan.months{month}, ' ', lan.of{1}, num2str(year));
            %GENERAL DATA
			%Personal data
			lan.surname		= 'Cognoms';
			lan.id			= 'DNI';
			lan.birth		= 'Data de naixement';
			lan.telephone	= 'Tel\`efon';
			lan.address		= 'Direcci\''o';
			lan.city		= 'Ciutat';
			lan.code		= 'Codi postal';
			%Current situation
			lan.employer	= 'Empresa';
			lan.department	= 'Departament';
			lan.job			= 'Lloc';
			lan.email		= 'Correu electr\`onic';
			%Academic background
			lan.title		= 'T\''itol';
			lan.university	= 'Universitat';
			lan.year		= 'Any';
			%RESEARCH
			%Projects
			lan.entity		= 'Entitat financera';
			lan.leader		= 'Investigador principal';
			lan.sdate		= 'Des de';
			lan.edate		= 'Fins a';
			lan.amount		= 'Import de la subvenci\''o';
			lan.people		= 'Nombre d''investigadors';
			%Papers
			lan.authors		= 'Autors';
			lan.publisher	= 'Editorial';
			lan.journal		= 'Revista';
			lan.reference	= 'Refer\`encia';
			lan.volume		= 'Volum';
			lan.pages		= 'P\`agines';
			%Conferences   
			lan.conference	= 'Congr\''es';
			lan.location	= 'Lloc de celebraci\''o';
			lan.contribution= 'Contribuci\''o';
			%Patents
			lan.description	= 'Descripci\''o';
			lan.number		= 'Nombre';
			lan.cdate		= 'Data de concessi\''o';
			lan.type		= 'Tipus';
			%TEACHING
			%Subjects
			lan.subject		= 'Assignatura';
			lan.plan		= 'Pla';
			lan.grade		= 'Curs';
			lan.hours		= 'Nombre d''hores';
			%OTHER ACHIEVEMENTS
			%Languages
			lan.language	= 'Idioma';
			lan.listening	= 'Comprensi\''o';
			lan.speaking	= 'Parla';
			lan.writing		= 'Escriptura';
		case 'en'
            lan.and                         = 'and';
            lan.abH                         = 'h';
            lan.in                          = 'in';
            lan.at                          = 'at';
            lan.with                        = 'with';
            lan.abRef                       = 'Ref';
            lan.mth                         = 'months';
            lan.page                        = 'Page';
            lan.of                          = 'of';
            lan.months                      = {'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'};
            lan.ordinals                    = {'st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th', 'th', 'th',...
                                               'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th',...
                                               'st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th', 'th', 'th',...
                                               'st'};
			%HEADERS
			lan.header.general				= 'General data';
			lan.header.personal				= 'Personal data';
			lan.header.company				= 'Current situation';
			lan.header.background			= 'Academic background';
			lan.header.research				= 'Research';
			lan.header.res_projects			= 'Participation in projects';
			lan.header.res_publications		= 'Publications';
			lan.header.res_papers			= 'Papers';
			lan.header.res_books			= 'Books';
			lan.header.res_int_conferences	= 'International conferences';
			lan.header.res_nat_conferences	= 'National conferences';
			lan.header.res_patents			= 'Patents';
			lan.header.res_collaborations	= 'Collaborations';
			lan.header.res_internships		= 'Internships';
			lan.header.res_scholarships		= 'Scholarships';
            lan.header.res_codes    		= 'Developed codes';
			lan.header.teaching				= 'Teaching';
			lan.header.tea_subjects			= 'University teaching';
			lan.header.tea_courses			= 'Given courses';
			lan.header.tea_seminars 		= 'Given seminars';
			lan.header.tea_workshops 		= 'Given workshops';
			lan.header.tea_materials		= 'Academic materials';
			lan.header.experience			= 'Employment experience';
			lan.header.other				= 'Other achievements';
			lan.header.oth_languages		= 'Languages (European level)';
			lan.header.oth_lan_titles		= 'Official titles';
			lan.header.oth_courses			= 'Courses and seminars';
			lan.header.oth_tec_courses		= 'Received courses';
			lan.header.oth_tec_seminars		= 'Received seminars';
			lan.header.oth_tec_workshops	= 'Received workshops';
			lan.header.oth_lan_courses		= 'Language courses';
			lan.header.oth_computer			= 'Computer knowledge';
			lan.header.oth_sof_general		= 'General use';
			lan.header.oth_sof_developer	= 'Developer';
			lan.header.oth_sof_specific		= 'Specific software';
			%TITLE PAGE
			lan.cvtitle		= 'Curriculum vitae';
			lan.pages		= 'Total number of pages';
			lan.name		= 'Name';
			lan.date		= 'Date';
			lan.disclaimer	= 'The person above declares that all data hereafter in this curriculum is true. Otherwise, he or she assumes all responsibility that inaccurate information could cause to third parties.';
            if args.usDate
				lan.frontDate	= horzcat(lan.months{month}, ' ', num2str(day, '%2i'), lan.ordinals{day}, ', ', num2str(year));
			else
                lan.frontDate	= horzcat(num2str(day, '%2i'), lan.ordinals{day}, ' ', lan.of, ' ', lan.months{month}, ', ', num2str(year));
            end
			%GENERAL DATA
			%Personal data
			lan.surname		= 'Surname';
			lan.id			= 'ID number';
			lan.birth		= 'Birth date';
			lan.telephone	= 'Telephone';
			lan.address		= 'Postal address';
			lan.city		= 'City';
			lan.code		= 'Postcode';
			%Current situation
			lan.employer	= 'Employer';
			lan.department	= 'Department';
			lan.job			= 'Position';
			lan.email		= 'E-mail';
			%Academic background
			lan.title		= 'Title';
			lan.university	= 'University';
			lan.year		= 'Year';
			%RESEARCH
			%Projects
			lan.entity		= 'Financial entity';
			lan.leader		= 'Main researcher';
			lan.sdate		= 'Starting date';
			lan.edate		= 'Ending date';
			lan.amount		= 'Financial support';
			lan.people		= 'Number of researchers';
			%Papers
			lan.authors		= 'Authors';
			lan.publisher	= 'Publisher';
			lan.journal		= 'Journal';
			lan.reference	= 'Reference';
			lan.volume		= 'Volume';
			lan.pages		= 'Pages';
			%Conferences
			lan.conference	= 'Conference';
			lan.location	= 'Location';
			lan.contribution= 'Contribution';
			%Patents
			lan.description	= 'Description';
			lan.number		= 'Number';
			lan.cdate		= 'Concession date';
			lan.type		= 'Type';
			%TEACHING
			%Subjects
			lan.subject		= 'Subject';
			lan.plan		= 'Plan';
			lan.grade		= 'Grade';
			lan.hours		= 'Number of hours';
			%OTHER ACHIEVEMENTS
			%Languages
			lan.language	= 'Language';
			lan.listening	= 'Listening';
			lan.speaking	= 'Speaking';
			lan.writing		= 'Writing';
	end
end

function r = arab2roman(n)
    %
    % arabic to roman number, only for n<21
    %
	if n > 20
		terminateProg('libLatexCV::arab2roman::tooManyTables', horzcat('A maximum of 20 tables is set but table ', n, ' was defined'))
	end
    roman = {'i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii', 'ix', 'x', 'xi', 'xii', 'xiii', 'xiv', 'xv', 'xvi', 'xvii', 'xviii', 'xix', 'xx'};
    r     = roman{n};
end

function checkPdfLatex()
    if ispc
        [flag, sysOut] = system('where pdflatex');
        if flag %1 if not found, 0 otherwise
            disp(sysOut)
            terminateProg('libLatexCV::checkPdfLatex::commandNotFound', 'Command pdflatex is not found, see the output above. You can obtain pdfLatex with MiKTeX for example')
        end
    else
        [flag, sysOut] = system('which pdflatex');
        if flag %1 if not found, 0 otherwise
            disp(sysOut)
            terminateProg('libLatexCV::checkPdfLatex::commandNotFound', 'Command pdflatex is not found, see the output above. You can obtain pdfLatex using your distro official repository')
        end
    end
end

function runPdfLatex(args)
    %check that pdflatex is in path
    checkPdfLatex()
	%run pdflatex twice for aux file
    for i = 1:2
        %create pdf with pdflatex
        [~, texOut] = system(horzcat('pdflatex -interaction=nonstopmode -output-directory=', args.outputPath, ' ', args.latexFile)); %ignore compiling errors and set output directory
        %show pdflatex output just in case of error
        if ~isempty(strfind(texOut, 'LaTeX Error')) || ~isempty(strfind(texOut, 'Fatal error')) ||  ~isempty(strfind(texOut, 'required by pdflatex'))
            disp(texOut)
            terminateProg('libLatexCV::runPdfLatex::unexpectedError', 'An unexpected error occurred while using pdflatex, see the output above')
        end
    end
end
    
function cleanTrash(varargin)
    %
    % clean some unnedded files
    %
    % load global variables
    global args
    %check if input arguments are read
    if isempty(args)
        return
    end
	% deletes unneeded files
    if fileattrib(fullfile(args.outputPath, strcat(args.outputName, '.aux')))
        delete(fullfile(args.outputPath, strcat(args.outputName, '.aux')))
    end
    if fileattrib(fullfile(args.outputPath, strcat(args.outputName, '.log')))
        delete(fullfile(args.outputPath, strcat(args.outputName, '.log')))
    end
    if fileattrib(fullfile(args.outputPath, strcat(args.outputName, '.out')))
        delete(fullfile(args.outputPath, strcat(args.outputName, '.out')))
    end
    if fileattrib(fullfile(args.outputPath, strcat(args.outputName, '.tex.backup')))
        delete(fullfile(args.outputPath, strcat(args.outputName, '.tex.backup')))
    end
    if fileattrib(args.debugFile)
        delete(args.debugFile)
    end
end

function f = openFile(filepath, opt)
    f = fopen(filepath, opt);
    if f < 0
        %file was not opened, terminate
        terminateProg('libLatexCV::openFile::fileNotOpened', horzcat('Could not open file ', filepath))
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
