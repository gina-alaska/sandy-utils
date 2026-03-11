#!/usr/bin/env ruby

require "pp"
nagg="/opt/cspp/SDR_4_1/libexec/bin/nagg"




geo_product_ids = ["GATMO", "GCRSO", "GAERO", "GCLDO", "GDNBO", "GNCCO", "GIGTO", "GIMGO", "GITCO", "GMGTO",
     "GMODO", "GMTCO", "GNHFO", "GOTCO", "GOSCO", "GONPO", "GONCO", "GCRIO", "GATRO", "ICDBG", "GOTCO"]

edr_product_ids = ["ICALI", "ICALM", "ICCCR", "ICISE", "ICMSE", "ICSTT", "ICTLI", "ICTLM", "IICMO", "IICMS", "SATMR", "SATMS",
     "SCRIS", "SOMPS", "SOMTC", "SOMSC", "SOMNC", "SVDNB", "SVI01", "SVI02", "SVI03", "SVI04", "SVI05", "SVM01",
     "SVM02", "SVM03", "SVM04", "SVM05", "SVM06", "SVM07", "SVM08", "SVM09", "SVM10", "SVM11", "SVM12", "SVM13",
     "SVM14", "SVM15", "SVM16", "TATMS", "REDRO", "OOTCO", "VAOOO", "VCBHO", "VCCLO", "VCEPO", "VCOTO", "VCTHO",
     "VCTPO", "VCTTO", "VI1BO", "VI2BO", "VI3BO", "VI4BO", "VI5BO", "VISTO", "VLSTO", "VM01O", "VM02O", "VM03O",
     "VM04O", "VM05O", "VM06O", "VNCCO", "VNHFO", "VOCCO", "VISAO", "VSCDO", "VSCMO", "VSICO", "VSSTO", "VSTYO",
     "VSUMO", "VIVIO", "REDRS", "OOTCS", "VAOOS", "VCBHS", "VCCLS", "VCEPS", "VCOTS", "VCTHS", "VCTPS", "VCTTS",
     "VISTS", "VLSTS", "VNCCS", "VNHFS", "VOCCS", "VISAS", "VSCDS", "VSCMS", "VSICS", "VSSTS", "VSTPS", "VSUMS",
     "VIVIS", "INCTO", "INPAK", "IIROO", "IIROS", "IMOPO", "IMOPS", "IVAMI", "IVAOT", "IVBPX", "IVCBH", "IVCDB",
     "IVCLT", "IVCOP", "IVCTP", "IVICC", "IVIIC", "IVIIW", "IVIQF", "IVIRT", "IVISR", "IVIWT", "IVPCM", "IVPCP",
     "IVPTP", "IVSIC", "IVSTP"]


id_list = []

MATCH_RE=/([A-Z0-9]+)_(\w+)_d\d+_t\d+_e\d+_b\d+_c\d+_\w+\.\w+/

#source dir
dir = ARGV.first

Dir.glob("#{dir}/*.h5").each do |item|
   #SVM16_j01_d20240710_t2315428_e2317073_b34428_c20240710233151315920_cspp_dev.h5 
   bits = File.basename(item).match(MATCH_RE)
   unless bits
      raise "#{item} not matched"
   end
   
   id_list << bits[1]
end


threads = []


id_list.uniq!
id_list.each do |id|
  if geo_product_ids.any?{|x| x==id}
    threads << Thread.new do 
    	system("#{nagg} -g #{id} --onefile -S -O cspp -D dev #{dir}/#{id}*.h5")
    end
  else
    if edr_product_ids.any?{|x| x==id}
      threads << Thread.new do 
      	system("#{nagg} -g no --onefile -S -t #{id} -O cspp -D dev #{dir}/#{id}*.h5")
      end
    else
        raise "#{id} not in the geo id list or the product id list"
    end
  end
end


threads.each { |thr| thr.join }
