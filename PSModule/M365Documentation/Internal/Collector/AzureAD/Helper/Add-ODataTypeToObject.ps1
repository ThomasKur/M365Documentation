Function Add-ODataTypeToObject(){
    <#
    .SYNOPSIS
    This function adds the @odata.type property to the passed objects to be able to translate them in the optimize step.
    .DESCRIPTION
    This function adds the @odata.type property to the passed objects to be able to translate them in the optimize step.
    .EXAMPLE
    $objs | Add-ODataTypeToObject -DataType AADRole
    Adds the @odata.type property to all objects with a value of AADRole
    .NOTES
    NAME: Add-ODataTypeToObject
    #>
    param(
        [Parameter(ValueFromPipeline,Mandatory)]
        [Object[]]
        $Objects,
        [Parameter(Mandatory)]
        [string]
        $DataType
        )
    Begin{

    }
    Process {
        foreach($object in $Objects){
            $object | Add-Member Noteproperty -Name "@odata.type" -Value $DataType -Force 
            $object
        }
    }
    End {

    }

}