package army.helpful.persistha.resource;



import army.helpful.persistha.message.model.ProblemContent;
import army.helpful.persistha.message.model.ProblemContentMessage;
import army.helpful.persistha.message.model.ProblemTitleMessage;
import army.helpful.persistha.repository.ProblemContentRepository;
import army.helpful.persistha.repository.ProblemTitleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;




@RestController
@RequestMapping(value = "/problemtitle")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class ProblemTitleResource {

    @Autowired
    ProblemTitleRepository problemTitleRepository;
    @Autowired
    ProblemContentRepository problemContentRepository;

    @GetMapping(value = "/all/{amount}", produces = MediaType.APPLICATION_JSON_UTF8_VALUE)
    public ProblemTitleMessage getAll(@PathVariable int amount) {
        Pageable pageWithAmountofElements = PageRequest.of(0, amount);

        ProblemTitleMessage titleMessage= new ProblemTitleMessage();

        titleMessage.setProblemTitleList(problemTitleRepository.getAllWithAmount(pageWithAmountofElements));

        return titleMessage;
    }



    @GetMapping(value = "/contents/{name}/{amount}")
    public ProblemContentMessage getContentsByTitle(@PathVariable String name, @PathVariable int amount) {
        Pageable pageWithAmountofElements = PageRequest.of(amount/10, 10);

        ProblemContentMessage contentMessage= new ProblemContentMessage();

        List<ProblemContent> contentList=  problemContentRepository.findByTitleWithAmount(name, pageWithAmountofElements);

        contentMessage.setProblemContentList(contentList);

        return contentMessage;
    }



}
