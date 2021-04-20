Function Get-AssignmentDetail(){
    <#
        .SYNOPSIS
        This function is used to print the assignment information to output.
        .DESCRIPTION
        This function is used to print the assignment information to output. It also gets group names.
        .EXAMPLE
        Get-AssignmentDetail -Assignments $assignment
        Prints the information from the Assignents Array
        .NOTES
        NAME: Get-AssignmentDetail
        #>
        param(
            $Assignments
        )
        $DocSecAssignment = New-Object DocSection
        $DocSecAssignment.Title = "Assignments"
        if($Assignments){
            $ExtendedInfo = @()

            if($Assignments.count -gt 1){
                foreach($Assignment in $Assignments){
                    $ExtendedInfo += Get-AssignmentDetailSingle -Assignment $Assignment
                }
            } else {
                $ExtendedInfo += Get-AssignmentDetailSingle -Assignment $Assignments
            }
            if($null -ne $ExtendedInfo){
                $DocSecAssignment.Objects = $ExtendedInfo 
            } else {
                $DocSecAssignment.Text = "No assignments"
            }
        } else {
            $DocSecAssignment.Text = "No assignments"
        }
        return $DocSecAssignment
}