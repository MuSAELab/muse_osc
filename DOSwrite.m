function DOSwrite(DataOutpuStream_obj, datum, type)
%DOSWRITE writes a datum to the DataOutputStream Java Oject
%TYPE defines how many bytes will be writen and how the are ordered

%View DataInputStream Java Methods in:
%http://docs.oracle.com/javase/7/docs/api/java/io/DataOutputStream.html


switch type
    case 'double'
        DataOutpuStream_obj.writeDouble(datum);
    case 'single'
        DataOutpuStream_obj.writeFloat(datum);
    case 'int32'
        DataOutpuStream_obj.writeInt(datum);
    case 'int8'
        DataOutpuStream_obj.writeByte(datum);
    case 'uint8'
        DataOutpuStream_obj.writeByte(datum);
end

