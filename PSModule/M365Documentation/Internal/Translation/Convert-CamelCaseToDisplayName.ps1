Function Convert-CamelCaseToDisplayName(){
    <#
    .SYNOPSIS
    This function to convert camel case to normal case
    .DESCRIPTION
    This function to convert camel case to normal case
    .EXAMPLE
    Convert-CamelCaseToDisplayName -Value "androidOsRestriction"
    Returns "Android Os Restriction"
    .NOTES
    NAME: Convert-CamelCaseToDisplayName
    #>
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $Value
    )
    $newString = ""
    if(([String]$Value).Contains(' ')){
      # If string already contains spaces don't change 
      $newString = $value
    } else {
      $stringChars = $value.GetEnumerator()
      $charIndex = 0
      $lastUpper = $false
      foreach ($char in $stringChars) {
        # If upper and not first character, add a space
        if ([char]::IsUpper($char) -eq "True" -and $charIndex -gt 0 -and $lastUpper -eq $false) {
          $newString = $newString + " " + $char.ToString()
          $lastUpper = $true
        } elseif ($charIndex -eq 0) {
          # If the first character, make it a capital always
          $newString = $newString + $char.ToString().ToUpper()
          $lastUpper = $true
        } else {
          $newString = $newString + $char.ToString()
          if([char]::IsUpper($char) -eq "True"){
            $lastUpper = $true
          }else {
            $lastUpper = $false
          }
        }
        $charIndex++
      }
    }
    return $newString

  }