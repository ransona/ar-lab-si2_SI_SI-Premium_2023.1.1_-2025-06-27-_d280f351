function flag = validateIp4Address(ipv4address)
%======== VALIDATE_IPADDRESS function validates whether the ip address being input by a User is Valid or not======%. 
%If the Ip address is valid then Flag will be set to 1 else Flag will be set to 0
%======== Input Parameters =========%
%ipaddress - String containing the Ip address given as input by the User.
%======== Output Parameters ========%
%flag - Output Value which indicates whether the Ipaddress being input is Valid or not.

%==== Initialise the Variables ====%
Valid_lengths = (7:15);
num_array = ones(1,4);
Check_flag = 1;
%==== Error Checking =======%
if ~ischar(ipv4address)
  flag = 0;
  return;
else
  length_ip = length(ipv4address);
  if ~ismember(length_ip,Valid_lengths)
    flag = 0;
    return;  
  else
    ipv4address = strcat(ipv4address,'.');  
    char_count = 1;
    part_count = 0;
    cr = [];
    part_array = cell(1,4);
    for index=1:4
        
     while (strcmpi(cr,'.') || char_count <=(part_count+3)) && num_array(index)==1
     cr = ipv4address(char_count);
     if ~strcmpi(ipv4address(char_count),'.')
     part_array{index} = strcat(part_array{index},ipv4address(char_count));
     else
     num_array(index) = 0;    
     end
     char_count = char_count + 1;
     end
     
     if isempty(part_array{index})
         part_array{index} = '999';
     end    
     
     if num_array(index) == 1 && strcmpi(ipv4address(char_count),'.') && ~isempty(str2num(part_array{index})) 
         
     temp_num = str2num(part_array{index});
     if ~(temp_num>=0 && temp_num<=255) 
     Check_flag = 0;
     num_array = zeros(1,4);
     break;    
     end 
     char_count = char_count + 1;
     num_array(index) = 0;
     
     elseif num_array(index) == 0 && ~isempty(str2num(part_array{index}))
     
     temp_num = str2num(part_array{index});
     if ~(temp_num>=0 && temp_num<=255) 
     Check_flag = 0;
     num_array = zeros(1,4);
     break;    
     end
     num_array(index) = 0;
     
     else
     Check_flag = 0;
     num_array = zeros(1,4);
     break;
     
     end
     
     part_count = char_count;

    end

  end
  
 if Check_flag == 0 && (sum(num_array) == 0)
  flag = 0;   
 else 
  flag = 1;   
 end

end

% Copyright (c) 2009, Shameemraj Nadaf
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
%     * Neither the name of the Tata Consultancy Services Ltd nor the names
%       of its contributors may be used to endorse or promote products derived
%       from this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

% ---------------------------------------------------------------------------
% Copyright (C) 2025 MBF Bioscience
% 
% ScanImage (R) 2025 is software to be used under the purchased terms
% Code may be modified, but not redistributed without the permission
% of MBF Bioscience
% 
% MBF BIOSCIENCE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, WITH
% RESPECT TO THIS PRODUCT, AND EXPRESSLY DISCLAIMS ANY WARRANTY OF
% MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
% IN NO CASE SHALL MBF BIOSCIENCE BE LIABLE TO ANYONE FOR ANY
% CONSEQUENTIAL OR INCIDENTAL DAMAGES, EXPRESS OR IMPLIED, OR UPON ANY OTHER
% BASIS OF LIABILITY WHATSOEVER, EVEN IF THE LOSS OR DAMAGE IS CAUSED BY
% MBF BIOSCIENCE'S OWN NEGLIGENCE OR FAULT.
% CONSEQUENTLY, MBF BIOSCIENCE SHALL HAVE NO LIABILITY FOR ANY
% PERSONAL INJURY, PROPERTY DAMAGE OR OTHER LOSS BASED ON THE USE OF THE
% PRODUCT IN COMBINATION WITH OR INTEGRATED INTO ANY OTHER INSTRUMENT OR
% DEVICE.  HOWEVER, IF MBF BIOSCIENCE IS HELD LIABLE, WHETHER
% DIRECTLY OR INDIRECTLY, FOR ANY LOSS OR DAMAGE ARISING, REGARDLESS OF CAUSE
% OR ORIGIN, MBF BIOSCIENCE MAXIMUM LIABILITY SHALL NOT IN ANY
% CASE EXCEED THE PURCHASE PRICE OF THE PRODUCT WHICH SHALL BE THE COMPLETE
% AND EXCLUSIVE REMEDY AGAINST MBF BIOSCIENCE.
% ---------------------------------------------------------------------------
