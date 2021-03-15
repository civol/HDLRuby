require "HDLRuby/template_expander"

##
# XCD file generator from 'xcd' properties
##########################################


# Generates a xcd file from the HDLRuby objects from +top+ using
# their 'xcd' properties.
# The file is saved in +path+ directory.
def xcd_generator(top, path)
    # Ensure top is a system.
    if top.is_a?(HDLRuby::Low::SystemI) then
        top = top.systemT
    elsif !top.is_a?(HDLRuby::Low::SystemT) then
        raise "The 'xcd_generator' driver can only be applied on SystemT objects."
    end

    # Get the name of the resulting file if any.
    if (top.properties.key?(:xcd_file)) then
        xcd_file = top.properties[:xcd_file].join
    else
        # Default file name.
        xcd_file = "default.xcd"
    end

    # Get the target template.
    xcd_target       = top.properties[:xcd_target].join
    xcd_target_name  = xcd_target
    xcd_target_name += ".xcd" unless xcd_target_name.end_with?(".xcd")
    xcd_target_tries = [ xcd_target_name,
                         File.join(path,xcd_target_name),
                         File.join(File.dirname(__FILE__),"xcd",xcd_target_name) ]
    xcd_target_file = xcd_target_tries.find { |fname| File.exist?(fname) }
    unless xcd_target_file then
        raise "XCD target template not found for #{xcd_target}."
    end
    # Load the template.
    template = File.read(xcd_target_file)

    # Gather the signals by xcd key.
    xcd2sig = top.each_signal.reduce([]) do |ar,sig|
        ar += sig.properties.each_with_key(:xcd).map do |val|
            [val,sig.name.to_s]
        end
    end

    # Create the template expander that will generate the xcd file.
    expander = TemplateExpander.new([
        [ /^\?.*(\n|\z)/, proc do |str| # Signal link to port
            if xcd2sig.any? do |match,rep|
                if str.include?(match) then
                    str = str.gsub("<>",rep)[1..-1]
                else
                    false
                end
            end then
            str
            else
                ""
            end
        end ]
    ])

    # # Generate the xcd file.
    # File.open(File.join(path,xcd_file),"w") do |file|
    #     # Generate the signals mapping.
    #     top.each_signal do |signal|
    #         signal.properties.each_with_key(:xcd) do |value|
    #             file << "#{value}\n"
    #         end
    #     end
    # end
    
    # Generate the xcd file.
    File.open(File.join(path,xcd_file),"w") do |file|
        expander.expand(template,file)
    end
end
