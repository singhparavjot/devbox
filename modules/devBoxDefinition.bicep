// ============================================================================
// Dev Box Definition Module
// ============================================================================

@description('Location for the Dev Box Definition')
param location string

@description('Name of the Dev Center')
param devCenterName string

@description('Name of the Dev Box Definition')
param devBoxDefinitionName string

@description('Dev Box SKU - compute size')
@allowed([
  'general_i_8c32gb256ssd_v2'
  'general_i_8c32gb512ssd_v2'
  'general_i_8c32gb1024ssd_v2'
  'general_i_16c64gb256ssd_v2'
  'general_i_16c64gb512ssd_v2'
  'general_i_16c64gb1024ssd_v2'
  'general_i_32c128gb512ssd_v2'
  'general_i_32c128gb1024ssd_v2'
  'general_i_32c128gb2048ssd_v2'
])
param devBoxSku string = 'general_i_8c32gb256ssd_v2'

@description('Dev Box Image (for marketplace images)')
param devBoxImage string = 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'

@description('Storage type for Dev Box OS disk')
@allowed([
  'ssd_256gb'
  'ssd_512gb'
  'ssd_1024gb'
])
param storageType string = 'ssd_256gb'

@description('Use custom gallery image instead of marketplace image')
param useGalleryImage bool = false

@description('Name of the attached gallery (required if useGalleryImage is true)')
param galleryName string = ''

@description('Name of the image definition in the gallery (required if useGalleryImage is true)')
param galleryImageName string = ''

// ============================================================================
// Reference to existing Dev Center
// ============================================================================

resource devCenter 'Microsoft.DevCenter/devcenters@2025-04-01-preview' existing = {
  name: devCenterName
}

// ============================================================================
// Variables
// ============================================================================

// Image reference for marketplace images (default gallery)
var marketplaceImageId = '${devCenter.id}/galleries/default/images/${devBoxImage}'

// Image reference for custom gallery images
var galleryImageId = '${devCenter.id}/galleries/${galleryName}/images/${galleryImageName}'

// Select the appropriate image based on configuration
var imageReferenceId = useGalleryImage ? galleryImageId : marketplaceImageId

// ============================================================================
// Dev Box Definition Resource
// ============================================================================

resource devBoxDefinition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2025-04-01-preview' = {
  parent: devCenter
  name: devBoxDefinitionName
  location: location
  properties: {
    imageReference: {
      id: imageReferenceId
    }
    sku: {
      name: devBoxSku
    }
    osStorageType: storageType
    hibernateSupport: 'Disabled'
  }
}

// ============================================================================
// Outputs
// ============================================================================

output id string = devBoxDefinition.id
output name string = devBoxDefinition.name
