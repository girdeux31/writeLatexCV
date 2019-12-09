%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %                                                                     %
% %     writeLatexCV  09/12/2019                                        %
% %                                                                     %
% % File name:        writeLatexCV.m                                    %
% % File type:        Function                                          %
% % File description: Write CV files in PDF format                      %
% % File version:     1.1.1                                             %
% %                                                                     %
% % Author: Carles Mesado                                               %
% % E-mail: mesado31@gmail.com                                          %
% %                                                                     %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Usage:
% 
%         writeLatexCV(input, output, language, currency, blue_links, us_date, us_paper)
% 
% All input arguments are optional:
%
%  - input:         input file name with CV data (default is 'writeLatexCV.inp')
%  
%  - output:        output PDF file name, without extension (default is 'writeLatexCV')
%  
%  - language:      language option, available options are:
%                       EN - English (default)
%                       ES - Spanish
%                       CA - Catalan
% 
%  - currency:      currency option, available options are:
%                       EUR - euros (default)
%                       USD - dollars
%                       GBP - pounds
%                       JPY - yens
%
%  - font_size:     font size in output PDF, available options are 8, 9, 10, 11 (default), 12, 14, 17 and 20
%
%  - blue_links:    colored links, available options are:
%                       false - links are black, just as other text (default)
%                       true  - links are blue, thus standing out from other text
%                     
%  - us_date:       date format in front page, available options are:
%                       false - European date format, for example 24th of May, 2010 (default)                                                                                 
%                       true  - American date format, for example May 24th, 2010
%
%  - us_paper:      paper size, available options are:
%                       false - A4 paper size is used (default)
%                       true  - letter paper size is used
% 
% The order of input arguments is strict, therefore, to change the date format, 'us_paper', you must introduce all input arguments.
% 
% For example, this command sets a user-specified option for the input and output names and the language (other options are set as default).
% 
%         writeLatexCV('John_CV_ES.txt', 'John_CV_ES', 'ES')
%                     
% Input arguments can also be introduced following the "keyword" syntax, that is 'parameter = value'.
% 
%         writeLatexCV('input = writeLatexCV.inp', 'output = writeLatexCV', 'language = EN', 'currency = EUR', 'font_size = 11', 'blue_links = false', 'us_date = false', 'us_paper = false')
%         
% With this syntax, input arguments can be introduced following any order and are still all optional.
% 
% For example, this command uses all input arguments by default but the currency and the paper size option:
%         
%         writeLatexCV('currency = USD', 'us_paper = true')
%
function writeLatexCV(varargin)
    
    %global variables declaration
    global args                                                                         %user options (input arguments)
    global vmargin hmargin titleCellColor                                               %pdf margins and title cell color
    global titleRowHeight sectRowHeight subSectRowHeight smallRowHeight stdRowHeight    %table row heights
	global colWidthMult1N colWidthMult2N colWidthMult3N colWidthMult4N colWidthMult5N   %table column width multipliers
    global colWidthPlus1N colWidthPlus2N colWidthPlus3N colWidthPlus5N                  %table column width increase
    
    
    %app variables
    appName    = 'writeLatexCV'; %app name
    appVersion = 'v1.1.1';       %app version

    %latex parameters
    vmargin             = 3.0;       %vertical margins (cm)
    hmargin             = 2.5;       %horizontal margins (cm)
    titleRowHeight 		= 0.8;       %height for title row (cm)
	sectRowHeight  		= 0.7;       %height for section title row (cm)
	subSectRowHeight 	= 0.6;       %height for subsection title row (cm)
    smallRowHeight 		= -0.25;     %height for struts (cm)
    stdRowHeight   		= 0.4;       %height for standard rows (cm)
    titleCellColor 		= 'gray!25'; %header cell table color (latex)
    colWidthMult1N 		= 1.00;      %column width multiplier for \linewidth (only 1 column)
    colWidthPlus1N 		= 0.012;     %column width increased for \linewidth (1 columns)
    colWidthMult2N 		= 0.49;      %column width multiplier for \linewidth (2 columns)
    colWidthPlus2N 		= 0.004;     %column width increased for \linewidth (2 columns)
	colWidthMult3N 		= 0.31;      %column width multiplier for \linewidth (3 columns)
    colWidthPlus3N 		= 0.01;      %column width increased for \linewidth (2 columns)
	colWidthMult4N 		= 0.234;     %column width multiplier for \linewidth (4 columns)
	colWidthMult5N 		= 0.16;      %column width multiplier for \linewidth (5 columns)
    colWidthPlus5N 		= -0.006;    %column width increased for \linewidth (5 columns)
        
    %load library
    eval('libLatexCV')
    
    %obtain input arguments according to user options
    args = getInputArguments(varargin);
    
    %load user data
    cv = readInputFile(args);
    
	%load language
	language = loadLanguage(args);
	
    %open file in matlab
    fout = openFile(args.latexFile, 'w');
    
    %define latex document
    writeDocumentDefinition(fout, args)

    %write preamble
    if isfield(cv, 'general') && isfield(cv.general, 'personal')
        writePreamble(fout, language, cv.general.personal)
    end

    %start latex document
    fprintf(fout,'\\begin{document}\n\n');
	
    %write title page
    if isfield(cv, 'general') && isfield(cv.general, 'personal')
        writePageTitle(fout,language, cv.general.personal)
    end
	
    %write tables
    ntab = 0;
    if isfield(cv, 'general')
		ntab = ntab + 1;
        writeTableGeneral(fout, language, cv.general, ntab);        %general data
    end
    if isfield(cv, 'research')
		ntab = ntab + 1;
        writeTableResearch(fout, language, cv.research, ntab);      %research data
    end
    if isfield(cv, 'teaching')
		ntab = ntab + 1;
        writeTableTeaching(fout, language, cv.teaching, ntab);      %research data
    end
    if isfield(cv, 'experience')
		ntab = ntab + 1;
        writeTableExperience(fout, language, cv.experience, ntab);  %previous experience data
    end
    if isfield(cv, 'other')
		ntab = ntab + 1;
        writeTableOther(fout, language, cv.other, ntab);            %other achievements
    end
    
    %end latex document
    fprintf(fout, '\\end{document}');

    %close matlab file
    fclose(fout);
   
    %run pdflatex to generate pdf
    runPdfLatex(args)
    
    %delete unneeded files
    cleanTrash()
    
    %farewell
    helpdlg(horzcat('Thanks for using ', appName, ' ', appVersion), 'Farewell')

end
