class TudDevice < ActiveRecord::Base
  
  #############################
  #     Instance Methods      #
  ############################
  
  #############################
  #     Class Methods      #
  #############################
  
  def self.drivers_license_scan
    xml_string = '<?xml version="1.0" encoding="UTF-8"?>
      <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:ns1="urn:TUDIntf" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:tns="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
         <SOAP-ENV:Body>
            <mns:ReadID xmlns:mns="urn:TUDIntf-ITUD" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
               <WorkstationIP xsi:type="xs:string">192.168.111.150</WorkstationIP>
               <WorkstationPort xsi:type="xs:int">10001</WorkstationPort>
               <Fields xsi:type="soapenc:Array" soapenc:arrayType="ns1:TTUDField[2]">
                  <item xsi:type="ns1:TTUDField">
                     <FieldName xsi:type="xs:string" />
                     <FieldValue xsi:type="xs:string" />
                  </item>
                  <item xsi:type="ns1:TTUDField">
                     <FieldName xsi:type="xs:string" />
                     <FieldValue xsi:type="xs:string" />
                  </item>
               </Fields>
            </mns:ReadID>
         </SOAP-ENV:Body>
      </SOAP-ENV:Envelope>'
    client = Savon.client(wsdl: "http://personalfinancesystem.com/tudauth/tudauth.dll/wsdl/ITUD")
    response = client.call(:encode, xml: xml_string)
    data = response.to_hash
#    data = response.body
#    data = response.to_xml
    return Hash.from_xml(data[:read_id_response][:return])["response"]
#    logger.debug data
#    success = data[:ttud_result][:success]
  end
  
  def self.scale_read
    xml_string = '<?xml version="1.0" encoding="UTF-8"?>
      <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:ns1="urn:TUDIntf" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:tns="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
         <SOAP-ENV:Body>
            <mns:ReadScale xmlns:mns="urn:TUDIntf-ITUD" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
               <WorkstationIP xsi:type="xs:string">192.168.111.150</WorkstationIP>
               <WorkstationPort xsi:type="xs:int">10000</WorkstationPort>
               <ConsecReads xsi:type="xs:int">3</ConsecReads>
            </mns:ReadScale>
         </SOAP-ENV:Body>
      </SOAP-ENV:Envelope>'
    client = Savon.client(wsdl: "http://personalfinancesystem.com/tudauth/tudauth.dll/wsdl/ITUD")
    response = client.call(:encode, xml: xml_string)
    data = response.to_hash
#    data = response.body
#    data = response.to_xml
    return data[:read_scale_response][:return]
#    logger.debug data
#    success = data[:ttud_result][:success]
  end
  
end

