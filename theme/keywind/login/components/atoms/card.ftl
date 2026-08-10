<#macro kw content="" footer="" header="">
  <div class="bg-card-bg p-8 rounded-xl text-main-text space-y-6">
    <#if header?has_content>
      <div class="space-y-4">
        ${header}
      </div>
    </#if>
    <#if content?has_content>
      <div class="space-y-4">
        ${content}
      </div>
    </#if>
    <#if footer?has_content>
      <div class="space-y-4">
        ${footer}
      </div>
    </#if>
  </div>
</#macro>
