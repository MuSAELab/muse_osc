function data = oscFormat(oscTag, oscData)
%OSCFORMAT orders OSCDATA based on the OSCTAG tags
%Returns an array of cells with the data divided by tag

%See OpenSoundControl specification 
%http://opensoundcontrol.org/spec-1_0

%Raymundo Cassani
%raymundo.cassani@gmail.com
%July 2014

indData =1;
for iTag = 1: numel(oscTag)
    switch oscTag(iTag)
        case 'f' %float32 case
            sizeBytes =4;
            a = oscData(indData:indData+sizeBytes-1);
            data{iTag} = swapbytes(typecast(uint8(a),'single'));
            indData = indData+sizeBytes;
        case 'i' %int32 case
            sizeBytes =4;
            a = oscData(indData:indData+sizeBytes-1);
            data{iTag} = swapbytes(typecast(uint8(a),'int32'));
            indData = indData+sizeBytes;
        case 's' %string case
            indStr = find(oscData(indData:end)==0,1,'first'); 
            data{iTag} =  char(oscData(indData:indStr-1))';
            sizeBytes = (ceil( (numel(data{iTag})+1)/ 4 )* 4);
            indData = indData+sizeBytes;
    end % switch    
end %for

end %function