
- [Introduction](#introduction)
- [Initialization](#initialization)
  - [Using PSCredential Object](#using-pscredential-object)
  - [Using plain username and secret](#using-plain-username-and-secret)
  - [(Optional) ImpersonationResourceID](#optional-impersonationresourceid)
- [Performing API calls](#performing-api-calls)
  - [GET](#get)
  - [POST](#post)
  - [PATCH](#patch)
  - [DELETE](#delete)
- [Filters](#filters)
  - [Create the object](#create-the-object)
  - [Methods](#methods)
    - [Add filter to filter group (items)](#add-filter-to-filter-group-items)
    - [Getters and Setters for fields:](#getters-and-setters-for-fields)
    - [Filtergroup (ArrayList):](#filtergroup-arraylist)
    - [Converting to JSON string](#converting-to-json-string)
    - [Example filter](#example-filter)

## Introduction

This is an Autotask REST API Module for Powershell, based on the AutotaskAPI Module by Kelvin Tegelaar https://github.com/KelvinTegelaar/AutotaskAPI .

---

## Initialization

You can use either a premade PSCredential object or plain Autotask username and secret, the latter will be converted to a PSCredential object.

The Zone is the subdomain in your instance URL: "https://webservices18.autotask.net...", here, it's webservices18.

Here you can find a list of all zones:
https://www.autotask.net/help/developerhelp/Content/APIs/General/API_Zones.htm

### Using PSCredential Object

```Powershell
$SecurePW = ConvertTo-SecureString -String $Secret -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential($Username, $SecurePW)
Initialize-ATRestApi -IntegrationCode $IntegrationCode -Credentials $Credentials -Zone "webservices18"
```

**or**

```Powershell
$Credentials = Get-Credential
Initialize-ATRestApi -IntegrationCode $IntegrationCode -Credentials $Credentials -Zone "webservices18"
```

### Using plain username and secret

```Powershell
Initialize-ATRestApi -IntegrationCode $IntegrationCode -Username $Username -Secret $Secret -Zone "webservices18"
```

### (Optional) ImpersonationResourceID

Refer to the official Autotask Rest API documentation:
https://www.autotask.net/help/developerhelp/Content/APIs/REST/General_Topics/REST_Security_Auth.htm

```Powershell
Initialize-ATRestApi -IntegrationCode $IntegrationCode -Credentials $Credentials -Zone "webservices18" -ImpersonationResourceID $ResourceID
```

---

## Performing API calls

There are no separate functions for each resource, you need to specify the resource you are trying to call with the -Resource parameter. Some resources require an ID, some require a ParentID and ChildID.

There is a dynamically generated list of possible resources for each function, you can use tab-completion for -Resource *TAB*.

You may need to refer to the official Datto documentation for the Autotask REST API for specifics:
https://www.autotask.net/help/developerhelp/Content/APIs/REST/REST_API_Home.htm

All possible resources for each Method are generated from the Autotask Rest API Swagger v1.json file. So a resource will only show up if it's available for the method.

Each function has an optional -PreviewURL switch parameter, which will print the URL for the chosen Resource without doing any API calls.

There is basic validation for URLs, 

### GET

* Getting specific objects via ID:

```Powershell
Get-ATRestResource -Resource <ResourceName> -(Parent)ID $ResourceID -ChildID $ChildID
```

* Using the filter query:

```Powershell
Get-ATRestResource -Resource <ResourceName> -Query $Filter
```

The module provides an easy way to generate a filter query json string, check out the documentation on filter objects below.

**Returns:** Object / array of objects.

### POST

To create an object body, you can use the function New-ATRestObjectModel:

```Powershell
      # Returns resource object with empty field values.
$ObjectBody = Get-ATRestObjectModel -Resource <ResourceName>
      # Returns object body prepopulated with type and picklist information, should only be used for reference, use an empty object for POST/PATCH operations
$ObjectBody = Get-ATRestObjectModel -Resource <ResourceName> -Example
```

You should not use this in scripts because the function makes 2 API calls just to create the object, it's better to create your own Hashtable or PSCustomObject with the values you require. It is very helpful in getting the picklist item IDs when writing your scripts, though.

The function returns a PSCustomObject. You can simply create your own PSCustomObject, or hashtable, whichever you prefer:

**Hashtable**
```Powershell
$TicketBody = @{
    title = "Ticket Title"
    description = "Example description for our Test Ticket."
    status = 1
    priority = 1
    queueID = 8
    resourceID = 12349876
    configurationItemID = 1920
    companyID = 1080
}
```

**PSCustomObject**
```Powershell
$TicketBody = [PSCustomObject]@{
    title = "Ticket Title"
    description = "Example description for our Test Ticket."
    status = 1
    priority = 1
    queueID = 8
    resourceID = 12349876
    configurationItemID = 1920
    companyID = 1080
}
```

As you can see, creating these objects is virtually identical, but there is one bit of difference internally, when handling both objects. The Autotask Rest API does not like empty field values in object bodies. Null values will be stripped from any PSCustomObject before each API call (*Note: 0 is not \$null, so a 0 as a value is perfectly fine*). This will not be done for hashtables so you need to make sure not to have any *$null* values. The API will throw an internal server error, status code 500, in case of empty values.

Dates also need to be in a specific format: "yyyy-MM-ddTHH:mm:ss.fffZ". However, you can simply pass a datetime object from Get-Date and the datetime object will be converted to UTC and a valid string before each API call.

```Powershell
New-ATRestResource -Resource <ResourceName> -ParentID $ID -Body $ObjectBody
```

**Returns:** ID of created object.

### PATCH

Same as post, but only select the required values and the values you want to change. Text with special (non-english) characters can get messed up with Powershell encoding so even if you make no changes to some text yourself, they can get changed.

Again, you can create your own hashtable or PSCustomObject, you could also create one with Get-ATRestObjectModel, but then do this before sending:

```Powershell
$ObjectBody = $Object | Select-Object -Property "List","of","changed","properties"
```

*Note: Select-Object does not work on hashtables, not like this anyway.*

```Powershell
Set-ATRestResource -Resource <ResourceName> -(Parent)ID $ID -ChildID $ChildID -Body $ObjectBody
```

Same object rules apply, check the section on POST if you haven't already.

**Returns:** ID of changed object.

### DELETE

Fairly straightforward, provide the ID of the object you want to delete, ParentID and ChildID for child objects.

```Powershell
Remove-ATRestResource -Resource <ResourceName> -(Parent)ID $ID -ChildID $ChildID
```

**Returns:** ID of deleted object.

---

## Filters

The Autotask REST API allows you to create very complex filters, you can write your own JSON filter String, or use the provided Filter object to create such a filter string.
It will always produce a valid JSON filter string, but there is very little validation of the actual values. You can type in whatever you want into OP, there is no check for all valid values.

**List of possible OP values:**

* and
* or
* exist
* notExit
* eq
* noteq
* gt
* gte
* lt
* lte
* beginsWith
* endsWith
* contains
* in
* notIn

For quick reference, every Filter object comes with an OPs field:

```Powershell
Write-Output $Filter.OPs.and
and
```

For a reference to all possible fields, you can use the Get-ATRestObjectFields function:

```Powershell
$FieldReference = Get-ATRestObjectFields -Resource <ResourceName>
```

It will return a PSCustomObject with prepopulated fields, which will return their own name as a string when called, so you can either type them in yourself whenever you need it, or use this object:

```Powershell
$TicketFields = Get-ATRestObjectFields -Resource Tickets
Write-Output $TicketFields.title
title
```

This uses the function Get-ATRestObjectModel underneath, so again, you should not use this in scripts.

### Create the object

* Empty object

```Powershell
$Filter = New-ATRestFilter
```

* Populated on creation, all parameters are optional

```Powershell
$Filter = New-ATRestFilter -Field $Field -Op $OP -Value $Value -UDF
```

### Methods

#### Add filter to filter group (items)

* Empty filter added to the **items** ArrayList, to group multiple filters using the **and**/**or** operators:

```Powershell
$Filter.AddGroupFilter()
```

* Only the OP field will be populated:

```Powershell
$Filter.AddGroupFilter($Op)
```

* Op and Field will be populated:

```Powershell
$Filter.AddGroupFilter($Field, $Op)
```

* Populated values for all fields except UDF, which will default to *$False* on creation:

```Powershell
$Filter.AddGroupFilter($Field, $Op, $Value)
```

* Populated values for all fields on creation:

```Powershell
$Filter.AddGroupFilter($Field, $Op, $Value, $UDF)
```

#### Getters and Setters for fields:

* Getters:

```Powershell
$Filter.GetField(); $Filter.GetOp(); $Filter.GetValue(); $Filter.GetUDF();
```

* Setters:

```Powershell
$Filter.SetField("referenceTitle"); $Filter.SetOp("beginsWith") ; $Filter.SetValue(""); $Filter.SetUDF($UDF);
```

*Note: You can access all fields with the . operator without using the getter and setter methods, Powershell does not prevent you from doing so, they are merely hidden from tab completion and intellisense.*

#### Filtergroup (ArrayList):

* Returns an ArrayList of Filter items you added with AddGroupFilter():

```Powershell
$Filter.GetItems()
```

* Returns specific filter item from the ArrayList. Index value is based on order of AddGroupFilter calls, so the first one you added with the AddGroupFilter method will be indexed as 0:

```Powershell
$Filter.GetItems($Index)
```

* Accessing grouped filters, this returns a filter object, so all the above methods work on it, for example:

```Powershell
$Filter.GetItems($Index).AddGroupFilter($Field, $Op, $Value)
```

* Removing a filter from *items*:

```Powershell
$Filter.RemoveGroupFilter($Index)
```

#### Converting to JSON string

* Generates a filter string ready for a query API call, does not need to be called explicitly when passing the object to Get-ATRestResource -SearchQuery $Filter. It will convert it automatically. The optional boolean parameter will output a formatted JSON string for readability, instead of a collapsed, single-line string.

```Powershell
$Filter.ToString($true)
```

#### Example filter

```Powershell
$Filter = New-ATRestFilter -Op "and"
$Filter.AddGroupFilter("title", "beginsWith", "Server")
$Filter.AddGroupFilter("resourceID", "eq", "12349876")
```

* Example output of collapsed JSON Filter:

```Powershell
$Filter.ToString()
{"Filter":[{"items":[{"field":"title","op":"beginsWith","udf":false,"value":"Server"},{"field":"resourceID","op":"eq","udf":false,"value":"12349876"}],"op":"and","udf":false}]}
```

* Example output of formatted JSON Filter:
  
```Powershell
$Filter.ToString($true)
{
    "Filter":  [
                   {
                       "items":  [
                                     {
                                         "field":  "title",  
                                         "op":  "beginsWith",
                                         "udf":  false,
                                         "value":  "Server"
                                     },
                                     {
                                         "field":  "resourceID",
                                         "op":  "eq",
                                         "udf":  false,
                                         "value":  "12349876"
                                     }
                                 ],
                       "op":  "and",
                       "udf":  false
                   }
               ]
}
```