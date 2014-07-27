function data = DISread(DataInputStream_obj, type)
%DISREAD reads one datum from the DataInputStream Java Oject
%TYPE defines how many bytes will be read and how the are ordered

%View DataInputStream Java Methods in:
%http://docs.oracle.com/javase/7/docs/api/java/io/DataInputStream.html#read%28byte[],%20int,%20int%29

switch type
    case 'double'
        data = DataInputStream_obj.readDouble();
    case 'single'
        data = DataInputStream_obj.readFloat();
    case 'int32'
        data = DataInputStream_obj.readInt();
    case 'int8'
        data = DataInputStream_obj.readByte();
    case 'uint8'
        data = DataInputStream_obj.readUnsignedByte();
end

